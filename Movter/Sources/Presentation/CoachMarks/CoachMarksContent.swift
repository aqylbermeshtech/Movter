//
//  CoachMarksContent.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

enum CoachMarksContent {
    static func tourSteps(isMentor: Bool, languageCode: String) -> [CoachMarkStep] {
        let copy = Copy.resolve(languageCode)
        var steps: [CoachMarkStep] = [
            CoachMarkStep(tab: nil, anchorId: nil, title: copy.welcomeTitle, message: copy.welcomeMessage),
            CoachMarkStep(tab: .main, anchorId: CoachMarkAnchorID.home, title: copy.mainTitle, message: isMentor ? copy.mainMentorMessage : copy.mainMessage)
        ]
        if isMentor {
            steps.append(
                CoachMarkStep(
                    tab: .main,
                    anchorId: CoachMarkAnchorID.fillProfile,
                    title: copy.fillProfileTitle,
                    message: copy.fillProfileMessage,
                    skipsWhenAnchorMissing: true
                )
            )
        }
        steps += [
            CoachMarkStep(
                tab: .catalog,
                anchorId: CoachMarkAnchorID.secondary,
                title: isMentor ? copy.calendarTitle : copy.catalogTitle,
                message: isMentor ? copy.calendarMessage : copy.catalogMessage
            ),
            CoachMarkStep(tab: .applications, anchorId: CoachMarkAnchorID.applications, title: copy.applicationsTitle, message: isMentor ? copy.applicationsMentorMessage : copy.applicationsMessage),
            CoachMarkStep(tab: .personalities, anchorId: CoachMarkAnchorID.personalities, title: copy.personalitiesTitle, message: copy.personalitiesMessage),
            CoachMarkStep(tab: .profile, anchorId: CoachMarkAnchorID.profileRoleSwitch, title: copy.profileTitle, message: copy.profileMessage)
        ]
        return steps
    }

    static func roleSelectionSteps(languageCode: String) -> [CoachMarkStep] {
        let copy = Copy.resolve(languageCode)
        return [
            CoachMarkStep(
                tab: nil,
                anchorId: CoachMarkAnchorID.roleMentee,
                title: copy.roleMenteeTitle,
                message: copy.roleMenteeMessage,
                skipsWhenAnchorMissing: true
            ),
            CoachMarkStep(
                tab: nil,
                anchorId: CoachMarkAnchorID.roleMentor,
                title: copy.roleMentorTitle,
                message: copy.roleMentorMessage,
                skipsWhenAnchorMissing: true
            )
        ]
    }

    struct Copy {
        let welcomeTitle: String
        let welcomeMessage: String
        let mainTitle: String
        let mainMessage: String
        let mainMentorMessage: String
        let fillProfileTitle: String
        let fillProfileMessage: String
        let catalogTitle: String
        let catalogMessage: String
        let calendarTitle: String
        let calendarMessage: String
        let applicationsTitle: String
        let applicationsMessage: String
        let applicationsMentorMessage: String
        let personalitiesTitle: String
        let personalitiesMessage: String
        let profileTitle: String
        let profileMessage: String
        let roleMenteeTitle: String
        let roleMenteeMessage: String
        let roleMentorTitle: String
        let roleMentorMessage: String
        let next: String
        let done: String
        let skip: String

        static func resolve(_ code: String) -> Copy {
            switch code {
            case "kk": return kk
            case "en": return en
            default: return ru
            }
        }

        static let ru = Copy(
            welcomeTitle: "Добро пожаловать в Mentor 👋",
            welcomeMessage: "Быстрый тур по приложению — покажем, что где находится. Это займёт 20 секунд.",
            mainTitle: "Главная",
            mainMessage: "Выберите направление сверху — ниже появится список менторов.",
            mainMentorMessage: "Ваши заявки и рекомендации. Отсюда начинается ваш день как ментора.",
            fillProfileTitle: "Заполните профиль",
            fillProfileMessage: "Это откроет приём заявок: расскажите о себе, добавьте навыки и планы сессий.",
            catalogTitle: "Каталог",
            catalogMessage: "Полный список менторов с фильтрами по навыкам, цене и рейтингу.",
            calendarTitle: "Календарь",
            calendarMessage: "Ваши сессии по дням и настройки доступности для записи.",
            applicationsTitle: "Заявки",
            applicationsMessage: "Ваши бронирования — активные и архив. Здесь входите в созвон и оцениваете сессии.",
            applicationsMentorMessage: "Входящие заявки от студентов — принимайте или отклоняйте, назначайте место встречи.",
            personalitiesTitle: "Личности",
            personalitiesMessage: "AI-наставники: проходите квесты с историческими личностями и развивайтесь.",
            profileTitle: "Профиль",
            profileMessage: "Ваш профиль, настройки, язык, подписка и вход/выход. Готово — приятного пользования!",
            roleMenteeTitle: "Если вы ищете помощь",
            roleMenteeMessage: "Выбирайте эту роль, чтобы найти ментора под свою цель: он разберёт вашу ситуацию и даст пошаговый план.",
            roleMentorTitle: "Если вы готовы делиться опытом",
            roleMentorMessage: "Эта роль — для экспертов: вы получаете заявки от менти и сами задаёте график, формат и стоимость сессий.",
            next: "Далее",
            done: "Готово",
            skip: "Пропустить"
        )

        static let kk = Copy(
            welcomeTitle: "Mentor қолданбасына қош келдіңіз 👋",
            welcomeMessage: "Қолданба бойынша жылдам тур — не қайда екенін көрсетеміз. 20 секунд алады.",
            mainTitle: "Басты бет",
            mainMessage: "Жоғарыдан бағытты таңдаңыз — төменде менторлар тізімі шығады.",
            mainMentorMessage: "Сіздің өтінімдеріңіз бен ұсыныстар. Ментор күніңіз осыдан басталады.",
            fillProfileTitle: "Профильді толтырыңыз",
            fillProfileMessage: "Бұл өтінімдерді қабылдауды ашады: өзіңіз туралы айтып, дағдылар мен сессия жоспарларын қосыңыз.",
            catalogTitle: "Каталог",
            catalogMessage: "Дағды, баға және рейтинг бойынша сүзгісі бар менторлардың толық тізімі.",
            calendarTitle: "Күнтізбе",
            calendarMessage: "Күндер бойынша сессияларыңыз және қолжетімділік баптаулары.",
            applicationsTitle: "Өтінімдер",
            applicationsMessage: "Брондарыңыз — белсенді және мұрағат. Осы жерден қоңырауға кіресіз.",
            applicationsMentorMessage: "Студенттерден келген өтінімдер — қабылдаңыз немесе бас тартыңыз.",
            personalitiesTitle: "Тұлғалар",
            personalitiesMessage: "AI-тәлімгерлер: тарихи тұлғалармен квесттерден өтіп, дамыңыз.",
            profileTitle: "Профиль",
            profileMessage: "Профиліңіз, баптаулар, тіл, жазылым және кіру/шығу. Дайын — сәтті пайдалану!",
            roleMenteeTitle: "Егер көмек іздесеңіз",
            roleMenteeMessage: "Мақсатыңызға сай ментор табу үшін осы рөлді таңдаңыз: ол жағдайыңызды талдап, қадамдық жоспар береді.",
            roleMentorTitle: "Егер тәжірибе бөліскіңіз келсе",
            roleMentorMessage: "Бұл рөл — сарапшыларға: менти өтінімдерін аласыз және кестені, форматты, бағаны өзіңіз белгілейсіз.",
            next: "Әрі қарай",
            done: "Дайын",
            skip: "Өткізіп жіберу"
        )

        static let en = Copy(
            welcomeTitle: "Welcome to Mentor 👋",
            welcomeMessage: "A quick tour of the app — we'll show you where everything is. Takes 20 seconds.",
            mainTitle: "Home",
            mainMessage: "Pick a field at the top and the mentors appear in the list below.",
            mainMentorMessage: "Your requests and recommendations. Your day as a mentor starts here.",
            fillProfileTitle: "Complete your profile",
            fillProfileMessage: "This unlocks incoming requests: tell about yourself, add skills and session plans.",
            catalogTitle: "Catalog",
            catalogMessage: "The full list of mentors with filters by skills, price and rating.",
            calendarTitle: "Calendar",
            calendarMessage: "Your sessions by day and your availability settings.",
            applicationsTitle: "Bookings",
            applicationsMessage: "Your bookings — active and archived. Join calls and rate sessions here.",
            applicationsMentorMessage: "Incoming requests from students — accept or decline, set the meeting place.",
            personalitiesTitle: "Personalities",
            personalitiesMessage: "AI mentors: take quests with historical figures and grow.",
            profileTitle: "Profile",
            profileMessage: "Your profile, settings, language, subscription and sign in/out. All set — enjoy!",
            roleMenteeTitle: "If you are looking for help",
            roleMenteeMessage: "Pick this role to find a mentor for your goal: they review your situation and give you a step-by-step plan.",
            roleMentorTitle: "If you are ready to share experience",
            roleMentorMessage: "This role is for experts: you receive requests from mentees and set your own schedule, format and pricing.",
            next: "Next",
            done: "Done",
            skip: "Skip"
        )
    }
}

