class ApartmentProfileSnapshot {
  const ApartmentProfileSnapshot({required this.name, required this.phone});

  final String name;
  final String phone;
}

class ApartmentBackendTarget {
  const ApartmentBackendTarget({
    required this.providerId,
    required this.serviceId,
    required this.currency,
  });

  final String providerId;
  final String serviceId;
  final String currency;
}

class ApartmentBackendBookingRequest {
  const ApartmentBackendBookingRequest({
    required this.target,
    required this.total,
    required this.scheduledAt,
    required this.metadata,
    this.serviceAvailabilityId,
    this.quantity = 1,
  });

  final ApartmentBackendTarget target;
  final String? serviceAvailabilityId;
  final int quantity;
  final int total;
  final DateTime scheduledAt;
  final Map<String, Object?> metadata;
}

class ApartmentRemoteBooking {
  const ApartmentRemoteBooking({required this.id});

  final String id;
}

enum ApartmentBackendPaymentState {
  paid,
  pending,
  requiresAction,
  failed,
  cancelled,
  unavailable,
}

class ApartmentBackendPaymentResult {
  const ApartmentBackendPaymentResult({
    required this.state,
    required this.message,
  });

  final ApartmentBackendPaymentState state;
  final String message;

  bool get isPaid => state == ApartmentBackendPaymentState.paid;
}

typedef ApartmentProfileProvider = ApartmentProfileSnapshot Function();

typedef ApartmentTargetResolver =
    Future<ApartmentBackendTarget?> Function(String province);

typedef ApartmentBookingCreator =
    Future<ApartmentRemoteBooking?> Function(
      ApartmentBackendBookingRequest request,
    );

typedef ApartmentPaymentExecutor =
    Future<ApartmentBackendPaymentResult> Function(
      String bookingId,
      String paymentMethodId,
    );

class ApartmentBackendBridge {
  const ApartmentBackendBridge({
    required this.profileProvider,
    required this.targetResolver,
    required this.bookingCreator,
    required this.paymentExecutor,
  });

  final ApartmentProfileProvider profileProvider;
  final ApartmentTargetResolver targetResolver;
  final ApartmentBookingCreator bookingCreator;
  final ApartmentPaymentExecutor paymentExecutor;
}

ApartmentBackendBridge? _apartmentBackendBridge;

void configureApartmentBackendBridge({
  required ApartmentProfileProvider profileProvider,
  required ApartmentTargetResolver targetResolver,
  required ApartmentBookingCreator bookingCreator,
  required ApartmentPaymentExecutor paymentExecutor,
}) {
  _apartmentBackendBridge = ApartmentBackendBridge(
    profileProvider: profileProvider,
    targetResolver: targetResolver,
    bookingCreator: bookingCreator,
    paymentExecutor: paymentExecutor,
  );
}

ApartmentProfileSnapshot? readApartmentProfile() =>
    _apartmentBackendBridge?.profileProvider();

Future<ApartmentBackendTarget?> resolveApartmentBackend(String province) async {
  final bridge = _apartmentBackendBridge;
  if (bridge == null) return null;
  return bridge.targetResolver(province);
}

Future<ApartmentRemoteBooking?> createApartmentBackendBooking(
  ApartmentBackendBookingRequest request,
) async {
  final bridge = _apartmentBackendBridge;
  if (bridge == null) return null;
  return bridge.bookingCreator(request);
}

Future<ApartmentBackendPaymentResult> executeApartmentBackendPayment(
  String bookingId,
  String paymentMethodId,
) async {
  final bridge = _apartmentBackendBridge;
  if (bridge == null) {
    return const ApartmentBackendPaymentResult(
      state: ApartmentBackendPaymentState.unavailable,
      message: 'خدمة الدفع الرئيسية غير مهيأة في هذا التشغيل.',
    );
  }
  return bridge.paymentExecutor(bookingId, paymentMethodId);
}
