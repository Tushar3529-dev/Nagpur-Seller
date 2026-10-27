import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/model/popup_users_model.dart';

class PopupUsersState extends Equatable {
  final PopupUsersAvailability? data;
  final bool isLoading;
  final String? error;

  /// The endpoint answered 403: this user isn't the main seller owner.
  final bool isForbidden;
  final DateTime? lastUpdated;

  const PopupUsersState({
    this.data,
    this.isLoading = false,
    this.error,
    this.isForbidden = false,
    this.lastUpdated,
  });

  /// Known to be the owner: the dashboard has loaded at least once.
  bool get hasAccess => data != null && !isForbidden;

  PopupUsersState copyWith({
    PopupUsersAvailability? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isForbidden,
    DateTime? lastUpdated,
  }) => PopupUsersState(
    data: data ?? this.data,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    isForbidden: isForbidden ?? this.isForbidden,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  /// Eligible first, then active, then everyone else; by name within each.
  List<PopupUser> get sortedUsers {
    int group(PopupUser user) => user.isEligible
        ? 0
        : user.currentOffer != null
        ? 1
        : user.isActive
        ? 2
        : 3;
    return [...?data?.users]..sort((a, b) {
      final byGroup = group(a).compareTo(group(b));
      return byGroup != 0 ? byGroup : a.name.compareTo(b.name);
    });
  }

  @override
  List<Object?> get props => [data, isLoading, error, isForbidden, lastUpdated];
}
