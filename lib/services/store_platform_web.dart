/// The web counterpart of [storePlatformName].
///
/// `PurchaseService.init` returns early on web, so nothing here ever reaches
/// a store. The value exists so the call stays total rather than needing a
/// null check at every use.
String storePlatformName() => 'web';
