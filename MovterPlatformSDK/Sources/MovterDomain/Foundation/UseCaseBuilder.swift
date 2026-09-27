//
//  UseCaseBuilder.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

///TODO: Переписать все под приложение
import Foundation

public final class UseCaseBuilder {
    
    public static let shared = UseCaseBuilder()
    
    private let bundle: Bundle
    
    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    // MARK: - Legal
    
//    public func makeGetLegalTermsUseCase() -> GetLegalTermsUseCaseProtocol {
//        let dataSource = LegalRemoteDataSource()
//        let repository = LegalRepositoryImpl(dataSource: dataSource)
//        return GetLegalTermsUseCase(repository: repository)
//    }
//    
//    // MARK: - MentorProfile
//    
//    public func makeGetMentorDetailsUseCase() -> GetMentorDetailsUseCaseProtocol {
//        let dataSource = MentorProfileLocalDataSource(bundle: bundle)
//        let repository = MentorProfileRepositoryImpl(dataSource: dataSource)
//        return GetMentorDetailsUseCase(repository: repository)
//    }
//    
//    // MARK: - ApplicationForm
//    
//    public func makeGetAvailableTimeSlotsUseCase() -> GetAvailableTimeSlotsUseCaseProtocol {
//        let dataSource = ApplicationFormLocalDataSource(bundle: bundle)
//        let repository = ApplicationFormRepositoryImpl(dataSource: dataSource)
//        return GetAvailableTimeSlotsUseCase(repository: repository)
//    }
//
//    public func makeGetAvailableDatesUseCase() -> GetAvailableDatesUseCaseProtocol {
//        let dataSource = AvailableDatesRemoteDataSource()
//        let repository = AvailableDatesRepositoryImpl(dataSource: dataSource)
//        return GetAvailableDatesUseCase(repository: repository)
//    }
//
//    public func makeGetAvailableSlotsUseCase() -> GetAvailableSlotsUseCaseProtocol {
//        let dataSource = AvailableSlotsRemoteDataSource()
//        let repository = AvailableSlotsRepositoryImpl(dataSource: dataSource)
//        return GetAvailableSlotsUseCase(repository: repository)
//    }
//    
//    public func makeSubmitBookingUseCase() -> SubmitBookingUseCaseProtocol {
//        let dataSource = ApplicationFormLocalDataSource(bundle: bundle)
//        let repository = ApplicationFormRepositoryImpl(dataSource: dataSource)
//        return SubmitBookingUseCase(repository: repository)
//    }
//    
//    // MARK: - ApplicationDetail
//    
//    public func makeSubmitApplicationUseCase() -> SubmitApplicationUseCaseProtocol {
//        let dataSource = ApplicationDetailRemoteDataSource()
//        let repository = ApplicationDetailRepositoryImpl(dataSource: dataSource)
//        return SubmitApplicationUseCase(repository: repository)
//    }
//    
//    // MARK: - ProfileMe
//
//    public func makeGetProfileMeUseCase() -> GetProfileMeUseCaseProtocol {
//        let dataSource = ProfileMeRemoteDataSource()
//        let repository = ProfileMeRepositoryImpl(dataSource: dataSource)
//        return GetProfileMeUseCase(repository: repository)
//    }
//
//    public func makeUpdateProfilePersonalUseCase() -> UpdateProfilePersonalUseCaseProtocol {
//        let dataSource = ProfileMeRemoteDataSource()
//        let repository = ProfileMeRepositoryImpl(dataSource: dataSource)
//        return UpdateProfilePersonalUseCase(repository: repository)
//    }
//
//    public func makeUpdateProfilePhotoUseCase() -> UpdateProfilePhotoUseCaseProtocol {
//        let dataSource = ProfileMeRemoteDataSource()
//        let repository = ProfileMeRepositoryImpl(dataSource: dataSource)
//        return UpdateProfilePhotoUseCase(repository: repository)
//    }
//
//    public func makeUpdateMenteeProfileUseCase() -> UpdateMenteeProfileUseCaseProtocol {
//        let dataSource = ProfileMeRemoteDataSource()
//        let repository = ProfileMeRepositoryImpl(dataSource: dataSource)
//        return UpdateMenteeProfileUseCase(repository: repository)
//    }
//
//    public func makeInitiateEmailChangeUseCase() -> InitiateEmailChangeUseCaseProtocol {
//        let dataSource = ProfileMeRemoteDataSource()
//        let repository = ProfileMeRepositoryImpl(dataSource: dataSource)
//        return InitiateEmailChangeUseCase(repository: repository)
//    }
//
//    public func makeConfirmEmailChangeUseCase() -> ConfirmEmailChangeUseCaseProtocol {
//        let dataSource = ProfileMeRemoteDataSource()
//        let repository = ProfileMeRepositoryImpl(dataSource: dataSource)
//        return ConfirmEmailChangeUseCase(repository: repository)
//    }
//    
//    // MARK: - MentorProfileSettings
//
//    public func makeUpdateMentorProfileSettingsUseCase() -> UpdateMentorProfileSettingsUseCaseProtocol {
//        let dataSource = MentorProfileSettingsRemoteDataSource()
//        let repository = MentorProfileSettingsRepositoryImpl(dataSource: dataSource)
//        return UpdateMentorProfileSettingsUseCase(repository: repository)
//    }
//
//    public func makeUpdateMentorProfileFullSettingsUseCase() -> UpdateMentorProfileFullSettingsUseCaseProtocol {
//        let dataSource = MentorProfileSettingsRemoteDataSource()
//        let repository = MentorProfileSettingsRepositoryImpl(dataSource: dataSource)
//        return UpdateMentorProfileFullSettingsUseCase(repository: repository)
//    }
//
//    public func makeCreateMentorPackageUseCase() -> CreateMentorPackageUseCaseProtocol {
//        let dataSource = MentorProfileSettingsRemoteDataSource()
//        let repository = MentorProfileSettingsRepositoryImpl(dataSource: dataSource)
//        return CreateMentorPackageUseCase(repository: repository)
//    }
//
//    public func makePublishMentorProfileUseCase() -> PublishMentorProfileUseCaseProtocol {
//        let dataSource = MentorProfileSettingsRemoteDataSource()
//        let repository = MentorProfileSettingsRepositoryImpl(dataSource: dataSource)
//        return PublishMentorProfileUseCase(repository: repository)
//    }
//
//    public func makeAIGenerateAboutUseCase() -> AIGenerateAboutUseCaseProtocol {
//        let dataSource = MentorProfileSettingsRemoteDataSource()
//        let repository = MentorProfileSettingsRepositoryImpl(dataSource: dataSource)
//        return AIGenerateAboutUseCase(repository: repository)
//    }
//
//    public func makeUpdateMentorPackageUseCase() -> UpdateMentorPackageUseCaseProtocol {
//        let dataSource = MentorProfileSettingsRemoteDataSource()
//        let repository = MentorProfileSettingsRepositoryImpl(dataSource: dataSource)
//        return UpdateMentorPackageUseCase(repository: repository)
//    }
//
//    public func makeDeleteMentorPackageUseCase() -> DeleteMentorPackageUseCaseProtocol {
//        let dataSource = MentorProfileSettingsRemoteDataSource()
//        let repository = MentorProfileSettingsRepositoryImpl(dataSource: dataSource)
//        return DeleteMentorPackageUseCase(repository: repository)
//    }
//
//    // MARK: - AIFillProfile
//
//    public func makeAIFillProfileUseCase() -> AIFillProfileUseCaseProtocol {
//        let dataSource = AIFillProfileRemoteDataSource()
//        let repository = AIFillProfileRepositoryImpl(dataSource: dataSource)
//        return AIFillProfileUseCase(repository: repository)
//    }
//
//    // MARK: - ProfileSetup
//
//    public func makeGetProfileSetupOptionsUseCase() -> GetProfileSetupOptionsUseCaseProtocol {
//        let dataSource = ProfileSetupLocalDataSource(bundle: bundle)
//        let repository = ProfileSetupRepositoryImpl(dataSource: dataSource)
//        return GetProfileSetupOptionsUseCase(repository: repository)
//    }
//    
//    public func makeSubmitProfileSetupUseCase() -> SubmitProfileSetupUseCaseProtocol {
//        let dataSource = ProfileSetupRemoteDataSource()
//        let repository = ProfileSetupRepositoryImpl(dataSource: dataSource)
//        return SubmitProfileSetupUseCase(repository: repository)
//    }
//
//    public func makeGetProfileSetupStatusUseCase() -> GetProfileSetupStatusUseCaseProtocol {
//        let dataSource = ProfileSetupRemoteDataSource()
//        let repository = ProfileSetupStatusRepositoryImpl(dataSource: dataSource)
//        return GetProfileSetupStatusUseCase(repository: repository)
//    }
//
//    // MARK: - Authentication
//
//    public func makeSignInUseCase() -> SignInUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = AuthRepositoryImpl(dataSource: dataSource)
//        return SignInUseCase(repository: repository)
//    }
//
//    public func makeLogoutUseCase() -> LogoutUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = AuthRepositoryImpl(dataSource: dataSource)
//        return LogoutUseCase(repository: repository)
//    }
//
//    public func makeDeleteAccountUseCase() -> DeleteAccountUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = AuthRepositoryImpl(dataSource: dataSource)
//        return DeleteAccountUseCase(repository: repository)
//    }
//
//    public func makeSwitchRoleUseCase() -> SwitchRoleUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = AuthRepositoryImpl(dataSource: dataSource)
//        return SwitchRoleUseCase(repository: repository)
//    }
//
//    public func makeGetAuthMeUseCase() -> GetAuthMeUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = AuthRepositoryImpl(dataSource: dataSource)
//        return GetAuthMeUseCase(repository: repository)
//    }
//
//    public func makeGoogleSignInUseCase() -> GoogleSignInUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = AuthRepositoryImpl(dataSource: dataSource)
//        return GoogleSignInUseCase(repository: repository)
//    }
//
//    public func makeAppleSignInUseCase() -> AppleSignInUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = AuthRepositoryImpl(dataSource: dataSource)
//        return AppleSignInUseCase(repository: repository)
//    }
//
//    // MARK: - OTP
//    
//    public func makeVerifyOTPUseCase() -> VerifyOTPUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = OTPRepositoryImpl(dataSource: dataSource)
//        return VerifyOTPUseCase(repository: repository)
//    }
//    
//    public func makeResendOTPUseCase() -> ResendOTPUseCaseProtocol {
//        let dataSource = RemoteAuthenticationDataSource()
//        let repository = OTPRepositoryImpl(dataSource: dataSource)
//        return ResendOTPUseCase(repository: repository)
//    }
//    
//    // MARK: - Country
//    
//    public func makeGetCountryByIdUseCase() -> GetCountryByIdUseCaseProtocol {
//        let dataSource = CountryLocalDataSource(bundle: bundle)
//        let repository = CountryRepositoryImpl(dataSource: dataSource)
//        return GetCountryByIdUseCase(repository: repository)
//    }
//    
//    public func makeGetGroupedCountriesUseCase() -> GetGroupedCountriesUseCaseProtocol {
//        let dataSource = CountryLocalDataSource(bundle: bundle)
//        let repository = CountryRepositoryImpl(dataSource: dataSource)
//        return GetGroupedCountriesUseCase(repository: repository)
//    }
//    
//    public func makeGetAllCountriesUseCase() -> GetAllCountriesUseCaseProtocol {
//        let dataSource = CountryLocalDataSource(bundle: bundle)
//        let repository = CountryRepositoryImpl(dataSource: dataSource)
//        return GetAllCountriesUseCase(repository: repository)
//    }
//    
//    public func makeSearchCountriesUseCase() -> SearchCountriesUseCaseProtocol {
//        let dataSource = CountryLocalDataSource(bundle: bundle)
//        let repository = CountryRepositoryImpl(dataSource: dataSource)
//        return SearchCountriesUseCase(repository: repository)
//    }
//    
//    // MARK: - Account
//    
//    public func makeGetAccountDataUseCase() -> GetAccountDataUseCaseProtocol {
//        let dataSource = AccountLocalDataSource()
//        let repository = AccountRepositoryImpl(dataSource: dataSource)
//        return GetAccountDataUseCase(repository: repository)
//    }
//    
//    // MARK: - Inquiry
//
//    public func makeGetInquiriesUseCase() -> GetInquiriesUseCaseProtocol {
//        let dataSource = InquiryLocalDataSource(bundle: bundle)
//        let repository = InquiryRepositoryImpl(dataSource: dataSource)
//        return GetInquiriesUseCase(repository: repository)
//    }
//
//    public func makeGetMenteeBookingsUseCase() -> GetMenteeBookingsUseCaseProtocol {
//        GetMenteeBookingsUseCase()
//    }
//
//    public func makeSubmitMenteeBookingRatingUseCase() -> SubmitMenteeBookingRatingUseCaseProtocol {
//        SubmitMenteeBookingRatingUseCase()
//    }
//
//    public func makeVerifyQRUseCase() -> VerifyQRUseCaseProtocol {
//        VerifyQRUseCase()
//    }
//
//    public func makeGetMentorQRUseCase() -> GetMentorQRUseCaseProtocol {
//        GetMentorQRUseCase()
//    }
//    
//    public func makeSaveMyInquiryUseCase() -> SaveMyInquiryUseCaseProtocol {
//        let dataSource = InquiryLocalDataSource(bundle: bundle)
//        return SaveMyInquiryUseCase(dataSource: dataSource)
//    }
//    
//    public func makeUpdateInquiryStatusUseCase() -> UpdateInquiryStatusUseCaseProtocol {
//        let dataSource = InquiryLocalDataSource(bundle: bundle)
//        let repository = InquiryRepositoryImpl(dataSource: dataSource)
//        return UpdateInquiryStatusUseCase(repository: repository)
//    }
//    
//    public func makeSubmitInquiryRatingUseCase() -> SubmitInquiryRatingUseCaseProtocol {
//        let dataSource = InquiryLocalDataSource(bundle: bundle)
//        let repository = InquiryRepositoryImpl(dataSource: dataSource)
//        return SubmitInquiryRatingUseCase(repository: repository)
//    }
//    
//    // MARK: - CalendarSettings
//
//    public func makeGetCalendarSettingsUseCase() -> GetCalendarSettingsUseCaseProtocol {
//        let dataSource = CalendarSettingsRemoteDataSource()
//        let repository = CalendarSettingsRepositoryImpl(dataSource: dataSource)
//        return GetCalendarSettingsUseCase(repository: repository)
//    }
//
//    public func makeUpdateCalendarSettingsUseCase() -> UpdateCalendarSettingsUseCaseProtocol {
//        let dataSource = CalendarSettingsRemoteDataSource()
//        let repository = CalendarSettingsRepositoryImpl(dataSource: dataSource)
//        return UpdateCalendarSettingsUseCase(repository: repository)
//    }
//
//    // MARK: - MentorInquiry
//
//    public func makeGetMentorInquiriesUseCase() -> GetMentorInquiriesUseCaseProtocol {
//        let dataSource = MentorBookingsRemoteDataSource()
//        let repository = MentorInquiryRepositoryImpl(dataSource: dataSource)
//        return GetMentorInquiriesUseCase(repository: repository)
//    }
//
//    public func makeGetMentorBookingsUseCase() -> GetMentorBookingsUseCaseProtocol {
//        let dataSource = MentorBookingsRemoteDataSource()
//        let repository = MentorInquiryRepositoryImpl(dataSource: dataSource)
//        return GetMentorBookingsUseCase(repository: repository)
//    }
//    
//    // MARK: - MentorConsultationDetail
//
//    public func makeGetMentorConsultationDetailUseCase() -> GetMentorConsultationDetailUseCaseProtocol {
//        let dataSource = MentorConsultationDetailRemoteDataSource()
//        let repository = MentorConsultationDetailRepositoryImpl(dataSource: dataSource)
//        return GetMentorConsultationDetailUseCase(repository: repository)
//    }
//
//    public func makeGetMeetingLinkUseCase() -> GetMeetingLinkUseCaseProtocol {
//        let dataSource = MentorConsultationDetailRemoteDataSource()
//        let repository = MentorConsultationDetailRepositoryImpl(dataSource: dataSource)
//        return GetMeetingLinkUseCase(repository: repository)
//    }
//
//    public func makeMarkMeetingJoinUseCase() -> MarkMeetingJoinUseCaseProtocol {
//        let dataSource = MentorConsultationDetailRemoteDataSource()
//        let repository = MentorConsultationDetailRepositoryImpl(dataSource: dataSource)
//        return MarkMeetingJoinUseCase(repository: repository)
//    }
//
//    public func makeAcceptBookingUseCase() -> AcceptBookingUseCaseProtocol {
//        let dataSource = MentorConsultationDetailRemoteDataSource()
//        let repository = MentorConsultationDetailRepositoryImpl(dataSource: dataSource)
//        return AcceptBookingUseCase(repository: repository)
//    }
//
//    public func makeUpdateMeetingPlaceUseCase() -> UpdateMeetingPlaceUseCaseProtocol {
//        let dataSource = MentorConsultationDetailRemoteDataSource()
//        let repository = MentorConsultationDetailRepositoryImpl(dataSource: dataSource)
//        return UpdateMeetingPlaceUseCase(repository: repository)
//    }
//
//    public func makeRejectBookingUseCase() -> RejectBookingUseCaseProtocol {
//        let dataSource = MentorConsultationDetailRemoteDataSource()
//        let repository = MentorConsultationDetailRepositoryImpl(dataSource: dataSource)
//        return RejectBookingUseCase(repository: repository)
//    }
//
//    public func makeCancelBookingUseCase() -> CancelBookingUseCaseProtocol {
//        let dataSource = MentorConsultationDetailRemoteDataSource()
//        let repository = MentorConsultationDetailRepositoryImpl(dataSource: dataSource)
//        return CancelBookingUseCase(repository: repository)
//    }
//
//    // MARK: - CatalogMentors
//
//    public func makeGetCatalogMentorsUseCase() -> GetCatalogMentorsUseCaseProtocol {
//        let dataSource = CatalogMentorsRemoteDataSource()
//        let repository = CatalogMentorsRepositoryImpl(dataSource: dataSource)
//        return GetCatalogMentorsUseCase(repository: repository)
//    }
//
//    public func makeGetCatalogMentorByIdUseCase() -> GetCatalogMentorByIdUseCaseProtocol {
//        let dataSource = CatalogMentorsRemoteDataSource()
//        let repository = CatalogMentorsRepositoryImpl(dataSource: dataSource)
//        return GetCatalogMentorByIdUseCase(repository: repository)
//    }
//
//    // MARK: - Favorites
//
//    public func makeGetFavoriteMentorsUseCase() -> GetFavoriteMentorsUseCaseProtocol {
//        let dataSource = FavoritesRemoteDataSource()
//        let repository = FavoritesRepositoryImpl(dataSource: dataSource)
//        return GetFavoriteMentorsUseCase(repository: repository)
//    }
//
//    public func makeAddFavoriteMentorUseCase() -> AddFavoriteMentorUseCaseProtocol {
//        let dataSource = FavoritesRemoteDataSource()
//        let repository = FavoritesRepositoryImpl(dataSource: dataSource)
//        return AddFavoriteMentorUseCase(repository: repository)
//    }
//
//    public func makeRemoveFavoriteMentorUseCase() -> RemoveFavoriteMentorUseCaseProtocol {
//        let dataSource = FavoritesRemoteDataSource()
//        let repository = FavoritesRepositoryImpl(dataSource: dataSource)
//        return RemoveFavoriteMentorUseCase(repository: repository)
//    }
//
//    public func makeGetFavoriteMentorStatusUseCase() -> GetFavoriteMentorStatusUseCaseProtocol {
//        let dataSource = FavoritesRemoteDataSource()
//        let repository = FavoritesRepositoryImpl(dataSource: dataSource)
//        return GetFavoriteMentorStatusUseCase(repository: repository)
//    }
//
//    // MARK: - CatalogDirections
//
//    public func makeGetCatalogDirectionsUseCase() -> GetCatalogDirectionsUseCaseProtocol {
//        let dataSource = CatalogDirectionsRemoteDataSource()
//        let repository = CatalogDirectionsRepositoryImpl(dataSource: dataSource)
//        return GetCatalogDirectionsUseCase(repository: repository)
//    }
//
//    // MARK: - ProfileSetupCatalog
//
//    public func makeGetProfileSetupCatalogUseCase() -> GetProfileSetupCatalogUseCaseProtocol {
//        let dataSource = ProfileSetupCatalogRemoteDataSource()
//        let repository = ProfileSetupCatalogRepositoryImpl(dataSource: dataSource)
//        return GetProfileSetupCatalogUseCase(repository: repository)
//    }
//
//    // MARK: - Geo
//
//    public func makeGetGeoCountriesUseCase() -> GetGeoCountriesUseCaseProtocol {
//        let dataSource = GeoRemoteDataSource()
//        let repository = GeoRepositoryImpl(dataSource: dataSource)
//        return GetGeoCountriesUseCase(repository: repository)
//    }
//
//    public func makeGetGeoCitiesUseCase() -> GetGeoCitiesUseCaseProtocol {
//        let dataSource = GeoRemoteDataSource()
//        let repository = GeoRepositoryImpl(dataSource: dataSource)
//        return GetGeoCitiesUseCase(repository: repository)
//    }
//
//    // MARK: - SkillsTaxonomy
//
//    public func makeGetSkillsTaxonomyUseCase() -> GetSkillsTaxonomyUseCaseProtocol {
//        let dataSource = SkillsTaxonomyRemoteDataSource()
//        let repository = SkillsTaxonomyRepositoryImpl(dataSource: dataSource)
//        return GetSkillsTaxonomyUseCase(repository: repository)
//    }
//
//    // MARK: - ServicePlanTemplates
//
//    public func makeGetServicePlanTemplatesUseCase() -> GetServicePlanTemplatesUseCaseProtocol {
//        let dataSource = ServicePlanTemplatesRemoteDataSource()
//        let repository = ServicePlanTemplatesRepositoryImpl(dataSource: dataSource)
//        return GetServicePlanTemplatesUseCase(repository: repository)
//    }
//    
//    // MARK: - RoleSelection
//    
//    public func makeSubmitRoleSelectionUseCase() -> SubmitRoleSelectionUseCaseProtocol {
//        let dataSource = RoleSelectionRemoteDataSource()
//        let repository = RoleSelectionRepositoryImpl(dataSource: dataSource)
//        return SubmitRoleSelectionUseCase(repository: repository)
//    }

    // MARK: - Devices / Push

    public func makeRegisterPushDeviceTokenUseCase() -> RegisterPushDeviceTokenUseCaseProtocol {
        let dataSource = RemoteDevicesDataSource()
        return RegisterPushDeviceTokenUseCase(dataSource: dataSource)
    }

//    public func makeGetNotificationsUseCase() -> GetNotificationsUseCaseProtocol {
//        let dataSource = RemoteNotificationsDataSource()
//        return GetNotificationsUseCase(dataSource: dataSource)
//    }
//
//    public func makeMarkNotificationReadUseCase() -> MarkNotificationReadUseCaseProtocol {
//        let dataSource = RemoteNotificationsDataSource()
//        return MarkNotificationReadUseCase(dataSource: dataSource)
//    }
//
//    public func makeMarkAllNotificationsReadUseCase() -> MarkAllNotificationsReadUseCaseProtocol {
//        let dataSource = RemoteNotificationsDataSource()
//        return MarkAllNotificationsReadUseCase(dataSource: dataSource)
//    }
//
//    public func makeRefreshTokenUseCase() -> RefreshTokenUseCaseProtocol {
//        RefreshTokenUseCase()
//    }
//
//    // MARK: - Subscription
//
//    public func makeLoadSubscriptionProductUseCase() -> LoadSubscriptionProductUseCaseProtocol {
//        let storeKit = StoreKitService()
//        return LoadSubscriptionProductUseCase(storeKit: storeKit)
//    }
//
//    public func makePurchaseSubscriptionUseCase() -> PurchaseSubscriptionUseCaseProtocol {
//        let storeKit = StoreKitService()
//        let dataSource = SubscriptionsRemoteDataSource()
//        let repository = SubscriptionRepositoryImpl(dataSource: dataSource)
//        return PurchaseSubscriptionUseCase(storeKit: storeKit, repository: repository)
//    }
//
//    public func makeGetSubscriptionStatusUseCase() -> GetSubscriptionStatusUseCaseProtocol {
//        let dataSource = SubscriptionsRemoteDataSource()
//        let repository = SubscriptionRepositoryImpl(dataSource: dataSource)
//        return GetSubscriptionStatusUseCase(repository: repository)
//    }
//
//    public func makeRestorePurchasesUseCase() -> RestorePurchasesUseCaseProtocol {
//        let storeKit = StoreKitService()
//        let dataSource = SubscriptionsRemoteDataSource()
//        let repository = SubscriptionRepositoryImpl(dataSource: dataSource)
//        return RestorePurchasesUseCase(storeKit: storeKit, repository: repository)
//    }
//
//    public func makeStartObservingSubscriptionTransactionsUseCase() -> StartObservingSubscriptionTransactionsUseCaseProtocol {
//        let storeKit = StoreKitService()
//        let dataSource = SubscriptionsRemoteDataSource()
//        let repository = SubscriptionRepositoryImpl(dataSource: dataSource)
//        return StartObservingSubscriptionTransactionsUseCase(storeKit: storeKit, repository: repository)
//    }
//
//    // MARK: - HistoricalMentors
//
//    public func makeGetHistoricalMentorsUseCase() -> GetHistoricalMentorsUseCaseProtocol {
//        let dataSource = HistoricalMentorsRemoteDataSource()
//        let repository = HistoricalMentorsRepositoryImpl(dataSource: dataSource)
//        return GetHistoricalMentorsUseCase(repository: repository)
//    }
//
//    // MARK: - SessionReviews
//
//    public func makeSubmitMenteeReviewUseCase() -> SubmitMenteeReviewUseCaseProtocol {
//        SubmitMenteeReviewUseCase(repository: makeSessionReviewsRepository())
//    }
//
//    public func makeGetSessionReviewsUseCase() -> GetSessionReviewsUseCaseProtocol {
//        GetSessionReviewsUseCase(repository: makeSessionReviewsRepository())
//    }
//
//    public func makeCompleteBookingUseCase() -> CompleteBookingUseCaseProtocol {
//        CompleteBookingUseCase(repository: makeSessionReviewsRepository())
//    }
//
//    private func makeSessionReviewsRepository() -> SessionReviewsRepositoryProtocol {
//        SessionReviewsRepositoryImpl(dataSource: SessionReviewsRemoteDataSource())
//    }
//
//    // MARK: - MeCapabilities
//
//    public func makeActivateRoleCapabilityUseCase() -> ActivateRoleCapabilityUseCaseProtocol {
//        ActivateRoleCapabilityUseCase(repository: makeMeCapabilitiesRepository())
//    }
//
//    public func makeDeactivateRoleCapabilityUseCase() -> DeactivateRoleCapabilityUseCaseProtocol {
//        DeactivateRoleCapabilityUseCase(repository: makeMeCapabilitiesRepository())
//    }
//
//    public func makeRestartRoleOnboardingUseCase() -> RestartRoleOnboardingUseCaseProtocol {
//        RestartRoleOnboardingUseCase(repository: makeMeCapabilitiesRepository())
//    }
//
//    private func makeMeCapabilitiesRepository() -> MeCapabilitiesRepositoryProtocol {
//        MeCapabilitiesRepositoryImpl(dataSource: MeCapabilitiesRemoteDataSource())
//    }
//
//    // MARK: - CatalogCategories
//
//    public func makeGetCatalogCategoriesUseCase() -> GetCatalogCategoriesUseCaseProtocol {
//        let dataSource = CatalogCategoriesRemoteDataSource()
//        let repository = CatalogCategoriesRepositoryImpl(dataSource: dataSource)
//        return GetCatalogCategoriesUseCase(repository: repository)
//    }
//
//    // MARK: - Taxonomy
//
//    public func makeGetTaxonomyIndustriesUseCase() -> GetTaxonomyIndustriesUseCaseProtocol {
//        GetTaxonomyIndustriesUseCase(repository: makeTaxonomyRepository())
//    }
//
//    public func makeGetTaxonomyProfessionsUseCase() -> GetTaxonomyProfessionsUseCaseProtocol {
//        GetTaxonomyProfessionsUseCase(repository: makeTaxonomyRepository())
//    }
//
//    public func makeGetTaxonomySpecializationOptionsUseCase() -> GetTaxonomySpecializationOptionsUseCaseProtocol {
//        GetTaxonomySpecializationOptionsUseCase(repository: makeTaxonomyRepository())
//    }
//
//    public func makeGetTaxonomyProfessionTermsUseCase() -> GetTaxonomyProfessionTermsUseCaseProtocol {
//        GetTaxonomyProfessionTermsUseCase(repository: makeTaxonomyRepository())
//    }
//
//    // MARK: - ProfessionalProfile
//
//    public func makeGetProfessionalProfileUseCase() -> GetProfessionalProfileUseCaseProtocol {
//        GetProfessionalProfileUseCase(repository: makeProfessionalProfileRepository())
//    }
//
//    public func makeSaveProfessionAssignmentUseCase() -> SaveProfessionAssignmentUseCaseProtocol {
//        SaveProfessionAssignmentUseCase(repository: makeProfessionalProfileRepository())
//    }
//
//    public func makeDeleteProfessionAssignmentUseCase() -> DeleteProfessionAssignmentUseCaseProtocol {
//        DeleteProfessionAssignmentUseCase(repository: makeProfessionalProfileRepository())
//    }
//
//    public func makeSaveProfileCompetencyUseCase() -> SaveProfileCompetencyUseCaseProtocol {
//        SaveProfileCompetencyUseCase(repository: makeProfessionalProfileRepository())
//    }
//
//    public func makeDeleteProfileCompetencyUseCase() -> DeleteProfileCompetencyUseCaseProtocol {
//        DeleteProfileCompetencyUseCase(repository: makeProfessionalProfileRepository())
//    }
//
//    private func makeTaxonomyRepository() -> TaxonomyRepositoryProtocol {
//        TaxonomyRepositoryImpl(dataSource: TaxonomyRemoteDataSource())
//    }
//
//    private func makeProfessionalProfileRepository() -> ProfessionalProfileRepositoryProtocol {
//        ProfessionalProfileRepositoryImpl(dataSource: ProfessionalProfileRemoteDataSource())
//    }
}
