import '../../features/payments/domain/payment.dart';

class PaymentUriPolicy {
  const PaymentUriPolicy._();

  static const _deepLinkSchemeByMethod = <String, String>{
    'jawali': 'jwali',
    'jwali': 'jwali',
    'jeeb': 'jeeb',
    'floosk': 'floosk',
    'floosak': 'floosk',
    'onecash': 'onecash',
    'alkuraimi': 'alkuraimi',
    'alkurimi_mobile': 'alkuraimi',
  };

  static Set<String> get configuredCheckoutHosts {
    const rawHosts = String.fromEnvironment('PAYMENT_CHECKOUT_HOSTS');
    return rawHosts
        .split(',')
        .map((host) => host.trim().toLowerCase())
        .where((host) => host.isNotEmpty)
        .toSet();
  }

  static Uri? selectTrustedUri(
    PaymentIntent payment, {
    required String paymentMethodId,
    required Set<String> allowedCheckoutHosts,
  }) {
    final deepLink = payment.deepLink;
    if (deepLink != null &&
        isTrustedDeepLink(deepLink, paymentMethodId: paymentMethodId)) {
      return deepLink;
    }

    final checkoutUrl = payment.checkoutUrl;
    if (checkoutUrl != null &&
        isTrustedCheckoutUrl(
          checkoutUrl,
          allowedCheckoutHosts: allowedCheckoutHosts,
        )) {
      return checkoutUrl;
    }
    return null;
  }

  static bool isTrustedDeepLink(Uri uri, {required String paymentMethodId}) {
    final expectedScheme = _deepLinkSchemeByMethod[paymentMethodId];
    return expectedScheme != null &&
        uri.scheme.toLowerCase() == expectedScheme &&
        uri.userInfo.isEmpty;
  }

  static bool isTrustedCheckoutUrl(
    Uri uri, {
    required Set<String> allowedCheckoutHosts,
  }) =>
      uri.scheme.toLowerCase() == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      allowedCheckoutHosts
          .map((host) => host.toLowerCase())
          .contains(uri.host.toLowerCase());
}
