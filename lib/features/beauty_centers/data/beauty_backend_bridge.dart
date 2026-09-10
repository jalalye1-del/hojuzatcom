class BeautyProfileSnapshot {
  const BeautyProfileSnapshot({required this.name, required this.phone});

  final String name;
  final String phone;
}

class BeautyBackendTarget {
  const BeautyBackendTarget({
    required this.providerId,
    required this.serviceId,
    required this.currency,
  });

  final String providerId;
  final String serviceId;
  final String currency;
}

class BeautyBackendBookingRequest {
  const BeautyBackendBookingRequest({
    required this.target,
    required this.total,
    required this.scheduledAt,
    required this.metadata,
    this.serviceAvailabilityId,
  });

  final BeautyBackendTarget target;
  final String? serviceAvailabilityId;
  final int total;
  final DateTime scheduledAt;
  final Map<String, Object?> metadata;
}

class BeautyRemoteBooking {
  const BeautyRemoteBooking({
    required this.id,
    required this.status,
    required this.total,
    required this.currency,
  });

  final int total;
  final String currency;

  final String id;
  final String status;
}

class BeautyPaymentMethod {
  const BeautyPaymentMethod({
    required this.code,
    required this.name,
    required this.type,
    this.logoUrl,
  });

  final String code;
  final String name;
  final String type;
  final Uri? logoUrl;
}

enum BeautyBackendPaymentState {
  paid,
  pending,
  requiresAction,
  failed,
  cancelled,
  unavailable,
}

class BeautyBackendPaymentResult {
  const BeautyBackendPaymentResult({
    required this.state,
    required this.message,
  });

  final BeautyBackendPaymentState state;
  final String message;

  bool get isPaid => state == BeautyBackendPaymentState.paid;
}

typedef BeautyProfileProvider = BeautyProfileSnapshot Function();

typedef BeautyTargetResolver =
    Future<BeautyBackendTarget?> Function(String province);

typedef BeautyBookingCreator =
    Future<BeautyRemoteBooking?> Function(BeautyBackendBookingRequest request);

typedef BeautyPaymentMethodsProvider =
    Future<List<BeautyPaymentMethod>> Function({
      required String currency,
      required int amount,
    });

typedef BeautyPaymentExecutor =
    Future<BeautyBackendPaymentResult> Function(
      String bookingId,
      String paymentMethodId,
    );

class BeautyBackendBridge {
  const BeautyBackendBridge({
    required this.profileProvider,
    required this.targetResolver,
    required this.bookingCreator,
    required this.paymentMethodsProvider,
    required this.paymentExecutor,
  });

  final BeautyProfileProvider profileProvider;
  final BeautyTargetResolver targetResolver;
  final BeautyBookingCreator bookingCreator;
  final BeautyPaymentMethodsProvider paymentMethodsProvider;
  final BeautyPaymentExecutor paymentExecutor;
}

BeautyBackendBridge? _beautyBackendBridge;

void configureBeautyBackendBridge({
  required BeautyProfileProvider profileProvider,
  required BeautyTargetResolver targetResolver,
  required BeautyBookingCreator bookingCreator,
  required BeautyPaymentMethodsProvider paymentMethodsProvider,
  required BeautyPaymentExecutor paymentExecutor,
}) {
  _beautyBackendBridge = BeautyBackendBridge(
    profileProvider: profileProvider,
    targetResolver: targetResolver,
    bookingCreator: bookingCreator,
    paymentMethodsProvider: paymentMethodsProvider,
    paymentExecutor: paymentExecutor,
  );
}

BeautyProfileSnapshot? readBeautyProfile() =>
    _beautyBackendBridge?.profileProvider();

Future<BeautyBackendTarget?> resolveBeautyBackend(String province) async {
  final bridge = _beautyBackendBridge;

  if (bridge == null) {
    return null;
  }

  return bridge.targetResolver(province);
}

Future<BeautyRemoteBooking?> createBeautyBackendBooking(
  BeautyBackendBookingRequest request,
) async {
  final bridge = _beautyBackendBridge;

  if (bridge == null) {
    return null;
  }

  return bridge.bookingCreator(request);
}

Future<List<BeautyPaymentMethod>> loadBeautyPaymentMethods({
  required String currency,
  required int amount,
}) async {
  final bridge = _beautyBackendBridge;

  if (bridge == null) {
    return const [];
  }

  return bridge.paymentMethodsProvider(currency: currency, amount: amount);
}

Future<BeautyBackendPaymentResult> executeBeautyBackendPayment(
  String bookingId,
  String paymentMethodId,
) async {
  final bridge = _beautyBackendBridge;

  if (bridge == null) {
    return const BeautyBackendPaymentResult(
      state: BeautyBackendPaymentState.unavailable,
      message: 'خدمة الدفع الرئيسية غير مهيأة في هذا التشغيل.',
    );
  }

  return bridge.paymentExecutor(bookingId, paymentMethodId);
}
