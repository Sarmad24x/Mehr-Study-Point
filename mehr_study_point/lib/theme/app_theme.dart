
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: GoogleFonts.poppinsTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F51B5), // Premium Indigo
      primary: const Color(0xFF3F51B5),
      onPrimary: Colors.white,
      secondary: const Color(0xFF00BFA5), // Teal accent for success/actions
      surface: Colors.white,
      background: const Color(0xFFF4F7FA), // Soft grayish-blue background
      error: const Color(0xFFE53935),
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F7FA),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF4F7FA),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.poppins(
        color: const Color(0xFF1A1C1E),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      color: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFF3F51B5).withOpacity(0.1),
      height: 70,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
              color: Color(0xFF3F51B5),
              fontWeight: FontWeight.w600,
              fontSize: 12);
        }
        return const TextStyle(color: Colors.grey, fontSize: 12);
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: Color(0xFF3F51B5), size: 26);
        }
        return const IconThemeData(color: Colors.grey, size: 24);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9FA8DA),
      brightness: Brightness.dark,
      primary: const Color(0xFF9FA8DA),
      surface: const Color(0xFF121212),
      background: const Color(0xFF0A0A0A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
  );
}
