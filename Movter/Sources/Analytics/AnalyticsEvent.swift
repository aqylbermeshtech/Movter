//
//  AnalyticsEvent.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

enum AnalyticsEvent {
    case appOpen
    case homeViewed
    case catalogViewed
    case searchPerformed
    case searchResultClicked(mentorId: String)
    case subscriptionPaywallViewed
    case subscriptionPurchaseStarted(productId: String)
    case planViewed(planId: String)

    case onboardingRoleSelected(role: String)
    case onboardingContinue(step: String)
    case onboardingSkip(step: String)

    case mentorProfileOpened(mentorId: String)
    case mentorBookSessionTap(mentorId: String)

    case bookingSlotSelected(mentorId: String, slot: String)

    case mentorCalendarSlotsAdded(slotsCount: Int)
    case mentorProfileSaved

    case catalogFilterApplied(filter: String, value: String)
    case catalogScrolledToEnd

    case sessionEntered(bookingId: String)

    var name: String {
        switch self {
        case .appOpen:                          return "app_open"
        case .homeViewed:                       return "home_viewed"
        case .catalogViewed:                    return "catalog_viewed"
        case .searchPerformed:                  return "search_performed"
        case .searchResultClicked:              return "search_result_clicked"
        case .subscriptionPaywallViewed:        return "subscription_paywall_viewed"
        case .subscriptionPurchaseStarted:      return "subscription_purchase_started"
        case .planViewed:                       return "plan_viewed"
        case .onboardingRoleSelected:           return "onboarding_role_selected"
        case .onboardingContinue:               return "onboarding_continue"
        case .onboardingSkip:                   return "onboarding_skip"
        case .mentorProfileOpened:              return "mentor_profile_viewed"
        case .mentorBookSessionTap:             return "booking_flow_started"
        case .bookingSlotSelected:              return "booking_slot_selected"
        case .mentorCalendarSlotsAdded:         return "mentor_calendar_slots_added"
        case .mentorProfileSaved:               return "mentor_profile_saved"
        case .catalogFilterApplied:             return "catalog_filter_applied"
        case .catalogScrolledToEnd:             return "catalog_scrolled_to_end"
        case .sessionEntered:                   return "session_entered"
        }
    }

    /// Free text never goes into the payload: no names, emails, phones, resume text,
    /// request messages or search queries.
    var payload: [String: String] {
        switch self {
        case .appOpen, .homeViewed, .catalogViewed, .searchPerformed, .subscriptionPaywallViewed:
            return [:]
        case .searchResultClicked(let mentorId):
            return ["mentor_id": mentorId]
        case .subscriptionPurchaseStarted(let productId):
            return ["product_id": productId]
        case .planViewed(let planId):
            return ["plan_id": planId]
        case .onboardingRoleSelected(let role):
            return ["role": role]
        case .onboardingContinue(let step):
            return ["step": step]
        case .onboardingSkip(let step):
            return ["step": step]
        case .mentorProfileOpened(let mentorId):
            return ["mentor_id": mentorId]
        case .mentorBookSessionTap(let mentorId):
            return ["mentor_id": mentorId]
        case .bookingSlotSelected(let mentorId, let slot):
            return ["mentor_id": mentorId, "slot": slot]
        case .mentorCalendarSlotsAdded(let slotsCount):
            return ["slots_count": String(slotsCount)]
        case .mentorProfileSaved:
            return [:]
        case .catalogFilterApplied(let filter, let value):
            return ["filter": filter, "value": value]
        case .catalogScrolledToEnd:
            return [:]
        case .sessionEntered(let bookingId):
            return ["booking_id": bookingId]
        }
    }
}
