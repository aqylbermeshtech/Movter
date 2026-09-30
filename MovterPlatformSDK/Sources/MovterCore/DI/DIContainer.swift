//
//  DIContainer.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation
import Swinject

nonisolated public final class DIContainer: @unchecked Sendable {
    public static let shared = DIContainer()
    
    private let assembler: Assembler
    private let synchronizedResolver: Resolver
    
    private init() {
        let container = Container()
        self.assembler = Assembler([], container: container)
        self.synchronizedResolver = container.synchronize()
    }
    
    public var resolver: Resolver {
        synchronizedResolver
    }
    
    public func register<Service>(_ serviceType: Service.Type, factory: @escaping (Resolver) -> Service) {
        let tempAssembly = TempAssembly<Service>(serviceType: serviceType, factory: factory)
        assembler.apply(assembly: tempAssembly)
    }
    
    public func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        synchronizedResolver.resolve(serviceType)
    }
    
    public func resolve<Service>() -> Service? {
        resolve(Service.self)
    }
    
    public func applyAssembly(_ assembly: Assembly) {
        assembler.apply(assembly: assembly)
    }
    
    public func applyAssemblies(_ assemblies: [Assembly]) {
        assembler.apply(assemblies: assemblies)
    }
}

nonisolated private final class TempAssembly<Service>: Assembly {
    private let serviceType: Service.Type
    private let factory: (Resolver) -> Service
    
    init(serviceType: Service.Type, factory: @escaping (Resolver) -> Service) {
        self.serviceType = serviceType
        self.factory = factory
    }
    
    func assemble(container: Container) {
        container.register(serviceType, factory: factory).inObjectScope(.container)
    }
}
