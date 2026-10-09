// swiftlint:disable all
// swiftformat:disable all

import Foundation

public enum LocalizedString {
  public static var allCategories: String { LocalizedString.tr("Localizable", "allCategories", fallback: "Все категории") }
  public static var back: String { LocalizedString.tr("Localizable", "back", fallback: "Назад") }
  public static var cancel: String { LocalizedString.tr("Localizable", "cancel", fallback: "Отмена") }
  public static var close: String { LocalizedString.tr("Localizable", "close", fallback: "Закрыть") }
  public static var confirm: String { LocalizedString.tr("Localizable", "confirm", fallback: "Подтвердить") }
  public static var delete: String { LocalizedString.tr("Localizable", "delete", fallback: "Удалить") }
  public static var done: String { LocalizedString.tr("Localizable", "done", fallback: "Готово") }
  public static var edit: String { LocalizedString.tr("Localizable", "edit", fallback: "Редактировать") }
  public static var error: String { LocalizedString.tr("Localizable", "error", fallback: "Ошибка") }
  public static var genericError: String { LocalizedString.tr("Localizable", "genericError", fallback: "Что-то пошло не так") }
  public static var home: String { LocalizedString.tr("Localizable", "home", fallback: "Главная") }
  public static var loading: String { LocalizedString.tr("Localizable", "loading", fallback: "Загрузка...") }
  public static var menu: String { LocalizedString.tr("Localizable", "menu", fallback: "Меню") }
  public static var networkError: String { LocalizedString.tr("Localizable", "networkError", fallback: "Ошибка сетевого соединения") }
  public static var noData: String { LocalizedString.tr("Localizable", "noData", fallback: "Нет данных") }
  public static var ok: String { LocalizedString.tr("Localizable", "ok", fallback: "ОК") }
  public static var retry: String { LocalizedString.tr("Localizable", "retry", fallback: "Повторить") }
  public static var save: String { LocalizedString.tr("Localizable", "save", fallback: "Сохранить") }
  public static var share: String { LocalizedString.tr("Localizable", "share", fallback: "Поделиться") }

  public enum Auth {
    public static var byEmail: String { LocalizedString.tr("Localizable", "auth.byEmail", fallback: "По почте") }
    public static var byPhone: String { LocalizedString.tr("Localizable", "auth.byPhone", fallback: "По телефону") }
    public static var emailPlaceholder: String { LocalizedString.tr("Localizable", "auth.emailPlaceholder", fallback: "E-mail") }
    public static var getCode: String { LocalizedString.tr("Localizable", "auth.getCode", fallback: "Получить код") }
    public static var orSignInWith: String { LocalizedString.tr("Localizable", "auth.orSignInWith", fallback: "Или войти через") }
    public static var phonePlaceholder: String { LocalizedString.tr("Localizable", "auth.phonePlaceholder", fallback: "000 000 00 00") }
    public static var skip: String { LocalizedString.tr("Localizable", "auth.skip", fallback: "Пропустить") }
    public static var welcome: String { LocalizedString.tr("Localizable", "auth.welcome", fallback: "Начните свой путь") }
  }

  public enum Error {
    public static var invalidEmail: String { LocalizedString.tr("Localizable", "error.invalidEmail", fallback: "Неправильный E-mail, попробуйте снова.") }
    public static var invalidPhone: String { LocalizedString.tr("Localizable", "error.invalidPhone", fallback: "Неправильный номер телефона, попробуйте снова.") }
  }

  public enum Otp {
    public static var anotherMethod: String { LocalizedString.tr("Localizable", "otp.anotherMethod", fallback: "Другой способ") }
    public static func attemptsLeft(_ p1: Int) -> String {
      return LocalizedString.tr("Localizable", "otp.attemptsLeft", p1, fallback: "Осталось %d попытки")
    }
    public static var errorWrongCode: String { LocalizedString.tr("Localizable", "otp.errorWrongCode", fallback: "Неверно указан код.\nПопробуйте ещё раз") }
    public static var goBackConfirm: String { LocalizedString.tr("Localizable", "otp.goBackConfirm", fallback: "Да") }
    public static var goBackMessage: String { LocalizedString.tr("Localizable", "otp.goBackMessage", fallback: "Код отправлен повторно, новый код придёт через 1 минуту") }
    public static var goBackTitle: String { LocalizedString.tr("Localizable", "otp.goBackTitle", fallback: "Вернуться назад?") }
    public static var resend: String { LocalizedString.tr("Localizable", "otp.resend", fallback: "Отправить код повторно") }
    public static func resendInSeconds(_ p1: Int) -> String {
      return LocalizedString.tr("Localizable", "otp.resendInSeconds", p1, fallback: "Через %d секунд")
    }
    public static func subtitleEmail(_ p1: Any) -> String {
      return LocalizedString.tr("Localizable", "otp.subtitleEmail", String(describing: p1), fallback: "Письмо с кодом отправлено на адрес %@")
    }
    public static func subtitleTelegram(_ p1: Any) -> String {
      return LocalizedString.tr("Localizable", "otp.subtitleTelegram", String(describing: p1), fallback: "Сообщение с кодом отправлено на номер %@")
    }
    public static var titleEmail: String { LocalizedString.tr("Localizable", "otp.titleEmail", fallback: "Введите код из Почты") }
    public static var titleTelegram: String { LocalizedString.tr("Localizable", "otp.titleTelegram", fallback: "Введите код из Telegram") }
  }

  public enum Policy {
    public static var privacy: String { LocalizedString.tr("Localizable", "policy.privacy", fallback: "Политики конфиденциальности") }
    public static var text: String { LocalizedString.tr("Localizable", "policy.text", fallback: "Нажимая кнопку \"Получить код\", вы принимаете условия ") }
  }

  public enum Search {
    public static var placeholder: String { LocalizedString.tr("Localizable", "search.placeholder", fallback: "Поиск") }
  }
}

// MARK: - Implementation Details

extension LocalizedString {
  static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftformat:enable all
// swiftlint:enable all
