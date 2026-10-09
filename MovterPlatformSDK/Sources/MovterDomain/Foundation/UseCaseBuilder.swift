//
//  UseCaseBuilder.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation

public final class UseCaseBuilder {
    
    public static let shared = UseCaseBuilder()
    
    private let bundle: Bundle
    
    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    // MARK: - Legal
    
    public func makeGetLegalTermsUseCase() -> GetLegalTermsUseCaseProtocol {
        let dataSource = LegalRemoteDataSource()
        let repository = LegalRepositoryImpl(dataSource: dataSource)
        return GetLegalTermsUseCase(repository: repository)
    }
    
    // MARK: - Profile
    
    public func makeGetProfileMeUseCase() -> GetProfileMeUseCaseProtocol {
        let dataSource = ProfileMeRemoteDataSource()
        let repository = ProfileMeRepositoryImpl(dataSource: dataSource)
        return GetProfileMeUseCase(repository: repository)
    }
    
    // MARK: - Authentication
    
    public func makeSignInUseCase() -> SignInUseCaseProtocol {
        let dataSource = RemoteAuthenticationDataSource()
        let repository = AuthRepositoryImpl(dataSource: dataSource)
        return SignInUseCase(repository: repository)
    }

    public func makeGoogleSignInUseCase() -> GoogleSignInUseCaseProtocol {
        let dataSource = RemoteAuthenticationDataSource()
        let repository = AuthRepositoryImpl(dataSource: dataSource)
        return GoogleSignInUseCase(repository: repository)
    }

    public func makeAppleSignInUseCase() -> AppleSignInUseCaseProtocol {
        let dataSource = RemoteAuthenticationDataSource()
        let repository = AuthRepositoryImpl(dataSource: dataSource)
        return AppleSignInUseCase(repository: repository)
    }

    // MARK: - OTP

    public func makeVerifyOTPUseCase() -> VerifyOTPUseCaseProtocol {
        let dataSource = RemoteAuthenticationDataSource()
        let repository = OTPRepositoryImpl(dataSource: dataSource)
        return VerifyOTPUseCase(repository: repository)
    }

    public func makeResendOTPUseCase() -> ResendOTPUseCaseProtocol {
        let dataSource = RemoteAuthenticationDataSource()
        let repository = OTPRepositoryImpl(dataSource: dataSource)
        return ResendOTPUseCase(repository: repository)
    }

    // MARK: - Country

    public func makeGetCountryByIdUseCase() -> GetCountryByIdUseCaseProtocol {
        let dataSource = CountryLocalDataSource(bundle: bundle)
        let repository = CountryRepositoryImpl(dataSource: dataSource)
        return GetCountryByIdUseCase(repository: repository)
    }

    public func makeGetGroupedCountriesUseCase() -> GetGroupedCountriesUseCaseProtocol {
        let dataSource = CountryLocalDataSource(bundle: bundle)
        let repository = CountryRepositoryImpl(dataSource: dataSource)
        return GetGroupedCountriesUseCase(repository: repository)
    }

    // MARK: - Devices

    public func makeRegisterPushDeviceTokenUseCase() -> RegisterPushDeviceTokenUseCaseProtocol {
        let dataSource = RemoteDevicesDataSource()
        return RegisterPushDeviceTokenUseCase(dataSource: dataSource)
    }
}
