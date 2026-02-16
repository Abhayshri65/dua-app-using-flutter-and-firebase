import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ADD KIYA
import 'screens/about_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/daily_dua_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/saved_duas_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/dua_detail_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_dua_form_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_notification_form_screen.dart';
import 'screens/access_denied_screen.dart';
import 'screens/admin_categories_screen.dart';
import 'screens/admin_subcategories_screen.dart';
import 'screens/subcategories_screen.dart';
import 'screens/subcategory_duas_screen.dart';
import 'screens/admin_notification_send_screen.dart';
import 'screens/notification_detail_screen.dart';
import 'screens/emotions_screen.dart';
import 'screens/emotion_dua_list_screen.dart';
import 'screens/admin_emotions_screen.dart';
import 'screens/dua_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ADD KIYA
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E1E1E)),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/favorites': (_) => const FavoritesScreen(),
        '/categories': (_) => const CategoriesScreen(),
        '/daily_dua': (_) => const DailyDuaScreen(),
        '/saved_duas': (_) => const SavedDuasScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/about': (_) => const AboutScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/search': (_) => const SearchResultsScreen(),
        '/dua-detail': (_) => const DuaDetailScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/admin-dua-form': (_) => const AdminDuaFormScreen(),
        '/admin-login': (_) => const AdminLoginScreen(),
        '/admin-notification-form': (_) => const AdminNotificationFormScreen(),
        '/admin-send-notification': (_) =>
            const AdminNotificationSendScreen(),
        '/access-denied': (_) => const AccessDeniedScreen(),
        '/admin-categories': (_) => const AdminCategoriesScreen(),
        '/admin-emotions': (_) => const AdminEmotionsScreen(),
        '/admin-subcategories': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final id = args['categoryId']?.toString() ?? '';
            final name = args['categoryName']?.toString() ?? 'Category';
            return AdminSubcategoriesScreen(
              categoryId: id,
              categoryName: name,
            );
          }
          return const AdminSubcategoriesScreen(
            categoryId: '',
            categoryName: 'Category',
          );
        },
        '/subcategories': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final id = args['categoryId']?.toString() ?? '';
            final name = args['categoryName']?.toString() ?? 'Category';
            return SubcategoriesScreen(categoryId: id, categoryName: name);
          }
          return const SubcategoriesScreen(
            categoryId: '',
            categoryName: 'Category',
          );
        },
        '/subcategory-duas': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final id = args['subcategoryId']?.toString() ?? '';
            final name = args['subcategoryName']?.toString() ?? 'Subcategory';
            return SubcategoryDuasScreen(
              subcategoryId: id,
              subcategoryName: name,
            );
          }
          return const SubcategoryDuasScreen(
            subcategoryId: '',
            subcategoryName: 'Subcategory',
          );
        },
        '/duaList': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final id = args['subcategoryId']?.toString() ?? '';
            final name = args['subcategoryName']?.toString() ?? 'Subcategory';
            return DuaListScreen(
              subcategoryId: id,
              subcategoryName: name,
            );
          }
          return const DuaListScreen(
            subcategoryId: '',
            subcategoryName: 'Subcategory',
          );
        },
        '/notification-detail': (_) => const NotificationDetailScreen(),
        '/emotions': (_) => const EmotionsScreen(),
        '/emotion-duas': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            final name = args['emotionName']?.toString() ?? 'Emotion';
            return EmotionDuaListScreen(emotionName: name);
          }
          return const EmotionDuaListScreen(emotionName: 'Emotion');
        },
      },
    );
  }
}
