/// 把例外轉成給使用者看的訊息。
///
/// `StateError.toString()` 會在前面加「Bad state:」，那是給開發者看的，
/// 使用者只需要看到我們自己寫的那句話。
String describeError(Object error) =>
    error is StateError ? error.message : error.toString();
