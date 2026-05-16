// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/widgets/custom_section.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/utils/user_helper.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/bloc/language/language_cubit.dart';
import 'package:hyper_local_seller/bloc/theme/theme_cubit.dart';
import 'package:hyper_local_seller/widgets/custom/custom_selection_sheet.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/master_api_service.dart';


class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileFetchEvent());
  }

  List<SettingsSectionData> _getSections(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCubit = context.read<ThemeCubit>();
    final languageCubit = context.read<LanguageCubit>();

    return [
      SettingsSectionData(
        title: l10n?.userPreference ?? 'User Preference',
        tiles: [
          SettingsTileData(
            img: ImagesPath.productSvg,
            title: l10n?.theme ?? 'Theme',
            subtitle: l10n?.selectTheme ?? 'Select your preferred theme',
            onTap: () {
              CustomSelectionSheet.show<ThemeMode>(
                context: context,
                title: l10n?.selectTheme ?? 'Select Theme',
                selectedValue: themeCubit.state,
                items: [
                  SelectionItem(
                    label: l10n?.systemDefault ?? 'System Default',
                    sublabel:
                        l10n?.systemMessage ?? 'Matches your device settings',
                    value: ThemeMode.system,
                    icon: Icons.brightness_auto,
                  ),
                  SelectionItem(
                    label: l10n?.light ?? 'Light',
                    sublabel: l10n?.lightMessage ?? 'Classic bright theme',
                    value: ThemeMode.light,
                    icon: Icons.light_mode,
                  ),
                  SelectionItem(
                    label: l10n?.dark ?? 'Dark',
                    sublabel:
                        l10n?.darkMessage ?? 'Gentle on eyes in low light',
                    value: ThemeMode.dark,
                    icon: Icons.dark_mode,
                  ),
                ],
                onSelected: (mode) => themeCubit.updateTheme(mode),
              );
            },
          ),
          SettingsTileData(
            img: ImagesPath.languageSvg,
            title: l10n?.language ?? 'Language',
            subtitle:
                l10n?.selectYourPreferredLanguage ??
                "Select your preferred language",
            onTap: () {
              CustomSelectionSheet.show<String>(
                context: context,
                title: l10n?.selectLanguage ?? 'Select Language',
                selectedValue: languageCubit.state.languageCode,
                items: [
                  SelectionItem(
                    label: 'English',
                    sublabel: 'English',
                    value: 'en',
                    leadingText: 'EN',
                  ),
                  SelectionItem(
                    label: 'Hindi',
                    sublabel: 'हिंदी',
                    value: 'hi',
                    leadingText: 'HI',
                  ),
                  SelectionItem(
                    label: 'Arabic',
                    sublabel: 'العربية',
                    value: 'ar',
                    leadingText: 'AR',
                  ),
                ],
                onSelected: (code) => languageCubit.changeLanguage(code),
              );
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: l10n?.storeManagement ?? "Store Management",
        tiles: [
          SettingsTileData(
            img: ImagesPath.productSvg,
            title: l10n?.manageProduct ?? "Manage Product",
            subtitle:
                l10n?.manageProductSubtitle ??
                "Add, edit, and organize products",
            onTap: () {
              if (!PermissionChecker.hasPermission(
                AppPermissions.productView,
              )) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewProducts ??
                      'You do not have permission to view products.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Manage Product button pressed');
              context.pushNamed(AppRoutes.productsFull);
            },
          ),
          SettingsTileData(
            img: ImagesPath.ordersSvg,
            title: l10n?.orders ?? "Orders",
            subtitle:
                l10n?.ordersSubtitle ?? "Manage and track customer orders",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.orderView)) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewOrders ??
                      'You do not have permission to view orders.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Manage Product button pressed');
              context.pushNamed(AppRoutes.ordersFull);
            },
          ),
          SettingsTileData(
            img: ImagesPath.storeSvg,
            title: l10n?.stores ?? "Stores",
            subtitle: l10n?.storesSubtitle ?? "Manage multiple stores",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.storeView)) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewStores ??
                      'You do not have permission to view stores.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('stores button pressed');
              context.pushNamed(AppRoutes.stores);
            },
          ),
          SettingsTileData(
            img: ImagesPath.categoriesSvg,
            title: l10n?.categories ?? "Categories",
            subtitle: l10n?.categoriesSubtitle ?? "Manage product categories",
            onTap: () {
              if (!PermissionChecker.hasPermission(
                AppPermissions.categoryView,
              )) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewCategories ??
                      'You do not have permission to view categories.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('categories button pressed');
              context.pushNamed(AppRoutes.categories);
            },
          ),
          SettingsTileData(
            img: ImagesPath.brandSvg,
            title: l10n?.brands ?? "Brands",
            subtitle: l10n?.brandsSubtitle ?? "Add and manage brands",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.brandView)) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewBrands ??
                      'You do not have permission to view brands.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('brands button pressed');
              context.pushNamed(AppRoutes.brands);
            },
          ),

          SettingsTileData(
            img: ImagesPath.attributesSvg,
            title: l10n?.attributes ?? "Attributes",
            subtitle: l10n?.attributesSubtitle ?? "Product attributes",
            onTap: () {
              if (!PermissionChecker.hasPermission(
                AppPermissions.attributeView,
              )) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewAttributes ??
                      'You do not have permission to view attributes.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('attributes button pressed');
              context.pushNamed(AppRoutes.attributes);
            },
          ),
          SettingsTileData(
            img: ImagesPath.faqSvg,
            title: l10n?.productFaqs ?? "Product FAQs",
            subtitle:
                l10n?.productFaqSubtitle ??
                'Manage your product questions & answers',
            onTap: () {
              if (!PermissionChecker.hasPermission(
                AppPermissions.productFaqView,
              )) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewProductFAQs ??
                      'You do not have permission to view product FAQs.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Product FAQs button pressed');
              context.pushNamed(AppRoutes.productFaqs);
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: l10n?.finance ?? "Finance",
        tiles: [
          SettingsTileData(
            img: ImagesPath.walletSvg,
            title: l10n?.wallet ?? "Wallet",
            subtitle:
                l10n?.walletSubtitle ??
                "Seller's wallet balance & transactions",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.walletView)) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewWallet ??
                      'You do not have permission to view your wallet.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('wallet button pressed');
              context.pushNamed(AppRoutes.wallet);
            },
          ),
          SettingsTileData(
            img: ImagesPath.earningsSvg,
            title: l10n?.earnings ?? 'Earnings',
            subtitle:
                l10n?.earningsSubtitle ?? "View commissions & settlements",
            onTap: () {
              if (!PermissionChecker.hasPermission(
                AppPermissions.earningView,
              )) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewEarnings ??
                      'You do not have permission to view earnings.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('earnings button pressed');
              context.pushNamed(AppRoutes.earnings);
            },
          ),
          SettingsTileData(
            img: ImagesPath.taxGroupSvg,
            title: l10n?.taxGroup ?? "Tax Group",
            subtitle: l10n?.taxGroupSubtitle ?? "View tax groups",
            onTap: () {
              if (!PermissionChecker.hasPermission(
                AppPermissions.taxRateView,
              )) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewTaxRates ??
                      'You do not have permission to view tax rates.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('tax_group button pressed');
              context.pushNamed(AppRoutes.taxGroup);
            },
          ),
          if (HiveStorage.isSubscriptionAvailable) ...[
            SettingsTileData(
              img: ImagesPath.subscriptionSvg,
              title: l10n?.subscriptionPlansTitle ?? "Subscription Plans",
              subtitle: l10n?.subscriptionSubtitle ?? "View subscription plans",
              onTap: () {
                if (!PermissionChecker.hasPermission(
                  AppPermissions.subscriptionView,
                )) {
                  showCustomSnackbar(
                    context: context,
                    message:
                        // l10n?.noPermissionViewSubscriptionPlans ??
                        'You do not have permission to view subscription plans.',
                    isWarning: true,
                  );
                  return;
                }
                debugPrint('subscription_plans button pressed');
                context.pushNamed(AppRoutes.subscriptionPlans);
              },
            ),
            SettingsTileData(
              img: ImagesPath.mySubscriptionSvg,
              title: "My Subscription",
              subtitle: "View your purchased subscription plans",
              onTap: () {
                if (!PermissionChecker.hasPermission(
                  AppPermissions.subscriptionView,
                )) {
                  showCustomSnackbar(
                    context: context,
                    message:
                        // l10n?.noPermissionViewSubscriptionPlans ??
                        'You do not have permission to view subscription plans.',
                    isWarning: true,
                  );
                  return;
                }
                debugPrint('my_subscription_plans button pressed');
                context.pushNamed(AppRoutes.subscriptionPlanHistory);
              },
            ),
          ],
        ],
      ),
      SettingsSectionData(
        title: l10n?.legal ?? 'Legal',
        tiles: [
          SettingsTileData(
            img: ImagesPath.privacyPolicySvg,
            title: l10n?.privacyPolicy ?? 'Privacy Policy',
            subtitle: l10n?.readPrivacyPolicy ?? 'Read our privacy policy',
            onTap: () {
              debugPrint('privacy_policy button pressed');
              context.pushNamed(AppRoutes.privacyPolicy);
            },
          ),
          SettingsTileData(
            img: ImagesPath.termsAndConditionsSvg,
            title: l10n?.termsAndConditions ?? 'Terms & Condition',
            subtitle:
                l10n?.readTermsAndConditions ?? 'Read our terms and conditions',
            onTap: () {
              debugPrint('terms_condition button pressed');
              context.pushNamed(AppRoutes.termsCondition);
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: l10n?.accountAndUsers ?? 'Account & Users',
        tiles: [
          SettingsTileData(
            img: ImagesPath.rolesAndPermissionSvg,
            title: l10n?.rolesAndPermissions ?? 'Roles & Permissions',
            subtitle:
                l10n?.rolesAndPermissionsSubtitle ?? "User access control",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.roleView)) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.noPermissionViewRolesAndPermissions ??
                      'You do not have permission to view roles and permissions.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('roles_permission button pressed');
              context.pushNamed(AppRoutes.rolesAndPermission);
            },
          ),
          SettingsTileData(
            img: ImagesPath.systemUsersSvg,
            title: l10n?.systemUsers ?? "System Users",
            subtitle: l10n?.systemUsersSubtitle ?? "Team members",
            onTap: () {
              if (!PermissionChecker.hasPermission(
                AppPermissions.systemUserView,
              )) {
                showCustomSnackbar(
                  context: context,
                  message: 'You do not have permission to view system users.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('system_users button pressed');
              context.pushNamed(AppRoutes.systemUsers);
            },
          ),
          SettingsTileData(
            img: ImagesPath.logoutSvg,
            title: l10n?.logout ?? "Logout",
            color: AppColors.errorColor,
            onTap: () {
              showAppAlertDialog(
                context: context,
                title: l10n?.logoutConfirmationTitle ?? "Logout",
                message:
                    l10n?.logoutConfirmationMessage ??
                    "Are you sure you want to log out from your account?",
                confirmText: l10n?.logoutConfirmButton ?? "Yes, Logout",
                cancelText: l10n?.logoutCancelButton ?? "Cancel",
                isDestructive: true,
                onConfirm: () {
                  // Clear ALL BLoC data FIRST while context is still valid
                  MasterApiService.clearAllApisData(context);
                  // Then trigger the actual logout (clears token & Hive)
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                onCancel: () {
                  debugPrint("Logout cancelled");
                },
              );
            },
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainer;

    return CustomScaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: Size(UIUtils.getScreenWidth(context), 120.0),
        child: _buildProfileAppBar(context, screenType),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            showCustomSnackbar(
              context: context,
              message: l10n?.logoutMessage ?? 'Logout successful',
            );
            context.go('/login');
          } else if (state is AuthFailure) {
            showCustomSnackbar(
              context: context,
              message: state.error,
              isError: true,
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._getSections(context).map((section) {
                if (section.tiles.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SettingsSection(
                  sectionTitle: section.title,
                  tiles: section.tiles,
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAppBar(BuildContext context, ScreenType screenType) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.primaryColor),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 24, 32),
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              // Determine the display data
              String name = UserHelper.name;
              String email = UserHelper.email;
              String mobile = UserHelper.mobile;
              String profileImage = UserHelper.profileImage;

              if (state is ProfileLoaded && state.profile.data != null) {
                name = state.profile.data!.name ?? name;
                email = state.profile.data!.email ?? email;
                mobile = state.profile.data!.mobile ?? mobile;
                profileImage = state.profile.data!.profileImage ?? profileImage;
              } else if (state is ProfileUpdateSuccess &&
                  state.updatedProfile.data != null) {
                name = state.updatedProfile.data!.name ?? name;
                email = state.updatedProfile.data!.email ?? email;
                mobile = state.updatedProfile.data!.mobile ?? mobile;
                profileImage =
                    state.updatedProfile.data!.profileImage ?? profileImage;
              } else if (state is ProfileUpdating &&
                  state.currentProfile?.data != null) {
                // While upgrading, keep showing old data if available in state
                name = state.currentProfile!.data!.name ?? name;
                email = state.currentProfile!.data!.email ?? email;
                mobile = state.currentProfile!.data!.mobile ?? mobile;
                profileImage =
                    state.currentProfile!.data!.profileImage ?? profileImage;
              }

              return Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CustomNetworkImage(
                      imageUrl: profileImage,
                      width: UIUtils.profileAvatarRadius(screenType) * 1.75,
                      height: UIUtils.profileAvatarRadius(screenType) * 2,
                      isCircle: true,
                      fit: BoxFit.cover,
                      errorWidget: Icon(
                        Icons.person,
                        size: UIUtils.profileIconSize(screenType),
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(width: UIUtils.gapMD(screenType)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: UIUtils.appTitle(screenType),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: UIUtils.body(screenType),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mobile,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: UIUtils.body(screenType),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('Edit Profile button pressed');
                      context.pushNamed(AppRoutes.profilePage);
                    },
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      TablerIcons.edit,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: UIUtils.appBarIcon(screenType),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
