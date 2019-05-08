import Foundation
import NIO
import PagerDutySwift

guard let token = ProcessInfo.processInfo.environment["PAGERDUTY_TOKEN"] else {
    print("Please set the PAGERDUTY_TOKEN environment variable with a valid API token.")
    exit(1)
}

guard CommandLine.arguments.count == 2, let escalationPolicyId = CommandLine.arguments.popLast() else {
    print("Please pass an argument for the Escalation Policy ID.")
    print("https://github.com/Yasumoto/Squire")
    exit(1)
}


func printService(service: Service) {
    let heading = "\(service.name): \(service.id)"
    print(heading)
    print("".padding(toLength: heading.count, withPad: "-", startingAt: 0))
    if let acknowledgementTimeout = service.acknowledgementTimeout {
        print(acknowledgementTimeout)
    }
    if let autoResolvetimeout = service.autoResolveTimeout {
        print(autoResolvetimeout)
    }
    print("\n")
}

let client = PagerDuty(token: token)

let policyFuture = client.getEscalationPolicy(id: escalationPolicyId, include: ["services"])
let servicesFuture: EventLoopFuture<[Service]> = policyFuture.flatMap { policy -> EventLoopFuture<[Service]> in
    let services = policy.services.map { client.getService(id: $0.id) }

    return EventLoopFuture.reduce([Service](), services, on: policyFuture.eventLoop) { services, service in
        return services + [service]
    }
}

let updatedServicesFuture: EventLoopFuture<[Service]> = servicesFuture.flatMap { (services) -> EventLoopFuture<[Service]> in
    let updatedServices = services.map { service -> EventLoopFuture<Service> in
        printService(service: service)

        var updatedService = service
        updatedService.acknowledgementTimeout = 0
        updatedService.autoResolveTimeout = 0
        return client.updateService(service: updatedService)
    }
    return EventLoopFuture.reduce([Service](), updatedServices, on: policyFuture.eventLoop) { services, service in
        return services + [service]
    }
}

_ = try updatedServicesFuture.map { services in
    services.map(printService)
}.wait()
