import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'database_helper.dart';
import 'screens/weather_screen.dart';
import 'screens/map_screen.dart';
import 'screens/spray_report_screen.dart';
import 'screens/networking_screen.dart';
import 'services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SQLite database on startup
  await LocalDatabaseHelper.instance.database;
  // Start with an empty in-memory profile until user logs in
  ProfileStore().save(name: '', age: '', crops: '', plotNames: [], plotAreas: []);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

// ============================================================
// THEME â€” colors lifted straight from the AgriPulse prototype
// ============================================================
class AppColors {
  static const Color forest = Color(0xFF0B3D2E);
  static const Color forestDeep = Color(0xFF06241A);
  static const Color sprout = Color(0xFFE8F4D9);
  static const Color orange = Color(0xFFFF8C42);
  static const Color green = Color(0xFF4ADE80);
  static const Color cyan = Color(0xFF2DD4FF);
  static const Color yellow = Color(0xFFFFD23F);
  static const Color glass = Color(0x0FFFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color neumoFace  = Color(0xFF0A2E20); // card face — slightly lighter than forestDeep
  static const Color neumoLight = Color(0xFF1A5C3A); // light shadow (top-left highlight)
  static const Color neumoDark  = Color(0xFF020F0A); // dark shadow (bottom-right depth)
  static const Color textBody = Color(0xFFCDEBD8);
  static const Color textMuted = Color(0xFFA9D9C2);
  static const Color textFooter = Color(0xFF6F9C85);
}

TextStyle headingFont({double size = 28, FontWeight weight = FontWeight.w700, Color color = Colors.white}) {
  return GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color, height: 1.1);
}

TextStyle bodyFont({double size = 14, FontWeight weight = FontWeight.w500, Color color = AppColors.textBody}) {
  return GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
}

TextStyle monoFont({double size = 24, FontWeight weight = FontWeight.w600, Color color = AppColors.yellow}) {
  return GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);
}

// ============================================================
// LANGUAGE SYSTEM
// ------------------------------------------------------------
// One central string table keyed by [language code][string key].
// Only 'en' is filled in for now (per your instruction). The other
// four language codes exist and fall back to English automatically
// â€” so the dropdown is fully functional today, and translating later
// is just filling in the blank maps below, nothing else changes.
// ============================================================
class AppStrings {
  static const Map<String, Map<String, String>> _table = {
    'en': {
      'eyebrow': 'PRECISPRAY',
      'hero_title': 'Intelligence,\ncultivated.',
      'hero_subtitle': 'Precision in every plot - ” Sustainable, Safe and Economic.',
      'mission_tag': 'OUR MISSION',
      'mission_title': 'Built around the field,\nnot the office.',
      'mission1_title': 'Sustainability',
      'mission1_body': 'Minimizes chemical waste and soil contamination using optimized, solar-powered spraying.',
      'mission2_title': "Farmer's Health",
      'mission2_body': 'Protects farmers from various chronic diseases caused by pesticide drift and blowback.',
      'mission3_title': 'Economics and Agriculture',
      'mission3_body': 'Reduces costs and improves crop yield through efficient, drift-free spraying.',
      'features_tag': 'FEATURES',
      'features_title': 'Data driven,\nearth-grown.',
      'feature1_title': 'Live field mapping dashboard',
      'feature1_body': 'Displays and saves spray route on map in application.',
      'feature2_title': 'Weather based spray planner',
      'feature2_body': 'Identifies safe spraying window on the basis of regional weather forecast.',
      'feature3_title': 'Chemical Calculator',
      'feature3_body': 'Know your pesticide savings and money saved before you even start spraying.',
      'feature4_title': 'Spray report',
      'feature4_body': 'Prepares a full-fledged report of the spray session.',
      'feature5_title': 'Networking',
      'feature5_body': 'Buy and sell crop produce directly with nearby farmers.',
      'about_tag': 'ABOUT US',
      'about_title': 'Built with you,\nfor the field.',
      'about_body': 'PreciSpray was founded to make precision farming accessible and practical. We replace guesswork with data, providing real-time soil and weather insights through an intuitive, farmer-first interface. Our mission is to optimize resource usage and help farmers grow with confidence - ”one acre at a time.',
      'footer': 'PreciSpray · scroll, hover and tap to explore',
      'drawer_irrigation': 'Irrigation control',
      'drawer_soil': 'Soil health',
      'drawer_weather': 'Weather alerts',
      'drawer_market': 'Market prices',
      'profile_name': 'Ramesh Sharma',
      'profile_sub': 'Nashik · 4.2 acres · Grapes',
      'drawer_profile': 'Profile',
      'drawer_chem_calc': 'Chemical calculator',
      'drawer_fav_weather': 'Favourable weather',
      'drawer_field_mapping': 'Field Mapping',
      'drawer_spray_report': 'Spray report',
      'drawer_networking': 'Networking',
      'drawer_tutorial': 'Tutorial',
      'drawer_features': 'Features',
      'drawer_about': 'About Us',
      'drawer_savings_tracker': 'Savings tracker',
      'profile_screen_title': 'Your Profile',
      'profile_field_name': 'Name',
      'profile_field_age': 'Age',
      'profile_field_crops': 'Crops grown',
      'profile_plots_title': 'Plots',
      'profile_plot_area_hint': 'Area (in acres)',
      'profile_submit': 'Submit',
    },
    'hi': {
      'eyebrow': 'प्रेसिस्प्रे',
      'hero_title': 'बुद्धिमत्ता,\nखेत में उगाई गई।',
      'hero_subtitle': 'हर खेत में सटीकता — टिकाऊ, सुरक्षित और किफायती।',
      'mission_tag': 'हमारा उद्देश्य',
      'mission_title': 'खेत के लिए बनाया गया,\nदफ़्तर के लिए नहीं।',
      'mission1_title': 'टिकाऊपन',
      'mission1_body': 'सौर ऊर्जा से चलने वाले अनुकूलित छिड़काव से रासायनिक अपव्यय और मिट्टी के संदूषण को कम करता है।',
      'mission2_title': 'किसान का स्वास्थ्य',
      'mission2_body': 'कीटनाशक के बहाव और वापसी से होने वाली विभिन्न पुरानी बीमारियों से किसानों की रक्षा करता है।',
      'mission3_title': 'अर्थशास्त्र और कृषि',
      'mission3_body': 'कुशल, बहाव-मुक्त छिड़काव के माध्यम से लागत कम करता है और फसल की पैदावार बढ़ाता है।',
      'features_tag': 'विशेषताएं',
      'features_title': 'डेटा-आधारित,\nधरती से उगाया गया।',
      'feature1_title': 'लाइव फील्ड मैपिंग डैशबोर्ड',
      'feature1_body': 'एप्लिकेशन में मानचित्र पर छिड़काव मार्ग दिखाता और सहेजता है।',
      'feature2_title': 'मौसम आधारित छिड़काव योजक',
      'feature2_body': 'क्षेत्रीय मौसम पूर्वानुमान के आधार पर सुरक्षित छिड़काव का समय बताता है।',
      'feature3_title': 'रासायनिक मिश्रण कैलकुलेटर',
      'feature3_body': 'आवश्यकता के अनुसार किसानों को मिश्रण अनुपात की मात्रा बताता है।',
      'feature4_title': 'छिड़काव रिपोर्ट',
      'feature4_body': 'छिड़काव सत्र की पूरी रिपोर्ट तैयार करता है।',
      'about_tag': 'हमारे बारे में',
      'about_title': 'आपके साथ बनाया गया,\nखेत के लिए।',
      'about_body': 'प्रेसिस्प्रे की स्थापना सटीक खेती को सुलभ और व्यावहारिक बनाने के लिए की गई थी। हम अनुमान को डेटा से बदलते हैं, एक सहज, किसान-केंद्रित इंटरफ़ेस के माध्यम से वास्तविक समय में मिट्टी और मौसम की जानकारी प्रदान करते हैं। हमारा लक्ष्य संसाधनों के उपयोग को अनुकूलित करना और किसानों को एक-एक एकड़ में आत्मविश्वास के साथ आगे बढ़ने में मदद करना है।',
      'footer': 'प्रेसिस्प्रे · स्क्रॉल करें, स्पर्श करें और जानें',
      'drawer_irrigation': 'सिंचाई नियंत्रण',
      'drawer_soil': 'मिट्टी का स्वास्थ्य',
      'drawer_weather': 'मौसम चेतावनी',
      'drawer_market': 'बाज़ार भाव',
      'profile_name': 'रमेश शर्मा',
      'profile_sub': 'नासिक · 4.2 एकड़ · अंगूर',
    },
    'ta': {
      'eyebrow': 'பிரெசிஸ்ப்ரே',
      'hero_title': 'நுண்ணறிவு,\nவயலில் வளர்ந்தது.',
      'hero_subtitle': 'ஒவ்வொரு நிலத்திலும் துல்லியம் — நிலையான, பாதுகாப்பான மற்றும் சிக்கனமான.',
      'mission_tag': 'எங்கள் நோக்கம்',
      'mission_title': 'வயலை மையமாகக் கொண்டது,\nஅலுவலகத்தை அல்ல.',
      'mission1_title': 'நிலைத்தன்மை',
      'mission1_body': 'சூரிய சக்தியால் இயங்கும் உகந்த தெளிப்பு மூலம் இரசாயன கழிவு மற்றும் மண் மாசுபாட்டை குறைக்கிறது.',
      'mission2_title': 'விவசாயியின் ஆரோக்கியம்',
      'mission2_body': 'பூச்சிக்கொல்லி பறப்பு மற்றும் திரும்புதலால் ஏற்படும் பல்வேறு நாள்பட்ட நோய்களிலிருந்து விவசாயிகளை பாதுகாக்கிறது.',
      'mission3_title': 'பொருளாதாரம் மற்றும் வேளாண்மை',
      'mission3_body': 'திறமையான, பறப்பு-இல்லா தெளிப்பு மூலம் செலவைக் குறைத்து மகசூலை மேம்படுத்துகிறது.',
      'features_tag': 'அம்சங்கள்',
      'features_title': 'தரவு சார்ந்தது,\nநிலத்தில் வளர்ந்தது.',
      'feature1_title': 'நேரடி வயல் வரைபட டாஷ்போர்டு',
      'feature1_body': 'பயன்பாட்டில் வரைபடத்தில் தெளிப்பு பாதையை காட்டி சேமிக்கிறது.',
      'feature2_title': 'வானிலை அடிப்படையிலான தெளிப்பு திட்டமிடுபவர்',
      'feature2_body': 'பிராந்திய வானிலை முன்னறிவிப்பின் அடிப்படையில் பாதுகாப்பான தெளிப்பு நேரத்தை அடையாளம் காட்டுகிறது.',
      'feature3_title': 'இரசாயன கலவை கால்குலேட்டர்',
      'feature3_body': 'தேவைக்கேற்ப விவசாயிகளுக்கு கலவை விகித அளவை வழங்குகிறது.',
      'feature4_title': 'தெளிப்பு அறிக்கை',
      'feature4_body': 'தெளிப்பு அமர்வின் முழுமையான அறிக்கையை தயாரிக்கிறது.',
      'about_tag': 'எங்களைப் பற்றி',
      'about_title': 'உங்களுடன் உருவாக்கப்பட்டது,\nவயலுக்காக.',
      'about_body': 'துல்லியமான விவசாயத்தை அணுகக்கூடியதாகவும் நடைமுறைக்குரியதாகவும் மாற்ற பிரெசிஸ்ப்ரே நிறுவப்பட்டது. ஊகங்களை தரவுகளுடன் மாற்றி, உள்ளுணர்வுள்ள, விவசாயி-முதன்மையான இடைமுகம் மூலம் நிகழ்நேர மண் மற்றும் வானிலை தகவல்களை வழங்குகிறோம். வளங்களின் பயன்பாட்டை மேம்படுத்தி, ஒரு ஏக்கர் ஒரு நேரத்தில் விவசாயிகள் நம்பிக்கையுடன் வளர உதவுவதே எங்கள் நோக்கம்.',
      'footer': 'பிரெசிஸ்ப்ரே · உருட்டவும், தொடவும், ஆராயவும்',
      'drawer_irrigation': 'நீர்ப்பாசன கட்டுப்பாடு',
      'drawer_soil': 'மண் ஆரோக்கியம்',
      'drawer_weather': 'வானிலை எச்சரிக்கைகள்',
      'drawer_market': 'சந்தை விலைகள்',
      'profile_name': 'ரமேஷ் சர்மா',
      'profile_sub': 'நாசிக் · 4.2 ஏக்கர் · திராட்சை',
    },
    'bn': {
            'eyebrow': 'প্রেসিস্প্রে',
      'hero_title': 'বুদ্ধিমত্তা,\nক্ষেতে চাষ করা।',
      'hero_subtitle': 'প্রতিটি জমিতে নির্ভুলতা — টিকসই, নিরাপদ এবং সাশ্রয়ী।',
      'mission_tag': 'আমাদের লক্ষ্য',
      'mission_title': 'মাঠকে ঘিরে তৈরি,\nঅফিস নয়।',
      'mission1_title': 'টিকাউত্ব',
      'mission1_body': 'সৌরশক্তি চালিত অপ্টিমাইজড স্প্রে ব্যবহার করে রাসায়নিক অপচয় এবং মাটি দূষণ কমায়।',
      'mission2_title': 'কৃষকের স্বাস্থ্য',
      'mission2_body': 'কীটনাশকের প্রবাহ ও ব্লোব্যাক থেকে সৃষ্ট বিভিন্ন দীর্ঘস্থায়ী রোগ থেকে কৃষকদের রক্ষা করে।',
      'mission3_title': 'অর্থনীতি ও কৃষি',
      'mission3_body': 'দক্ষ, প্রবাহমুক্ত স্প্রে-এর মাধ্যমে খরচ কমায় এবং ফসলের ফলন বাড়ায়।',
      'features_tag': 'বৈশিষ্ট্য',
      'features_title': 'তথ্য-চালিত,\nমাটিতে উত্থিত।',
      'feature1_title': 'লাইভ ফিল্ড ম্যাপিং ড্যাশবোর্ড',
      'feature1_body': 'অ্যাপ্লিকেশনে মানচিত্রে স্প্রে রুট প্রদর্শন ও সংরক্ষণ করে।',
      'feature2_title': 'আবহাওয়া ভিত্তিক স্প্রে পরিকল্পক',
      'feature2_body': 'আঞ্চলিক আবহাওয়ার পূর্বাভাসের ভিত্তিতে নিরাপদ স্প্রে করার সময় চিহ্নিত করে।',
      'feature3_title': 'রাসায়নিক মিশ্রণ ক্যালকুলেটর',
      'feature3_body': 'প্রয়োজন অনুযায়ী কৃষকদের মিশ্রণ অনুপাতের পরিমাণ প্রদান করে।',
      'feature4_title': 'স্প্রে রিপোর্ট',
      'feature4_body': 'স্প্রে সেশনের একটি সম্পূর্ণ রিপোর্ট তৈরি করে।',
      'about_tag': 'আমাদের সম্পর্কে',
      'about_title': 'আপনার সাথে তৈরি,\nমাঠের জন্য।',
      'about_body': 'প্রেসিস্প্রে নির্ভুল কৃষিকে সহজলভ্য ও ব্যবহারিক করার জন্য প্রতিষ্ঠিত হয়েছিল। আমরা অনুমানকে তথ্য দিয়ে প্রতিস্থাপন করি, একটি স্বজ্ঞাত, কৃষক-প্রথম ইন্টারফেসের মাধ্যমে রিয়েল-টাইম মাটি এবং আবহাওয়ার তথ্য প্রদান করি। আমাদের লক্ষ্য সম্পদ ব্যবহার অপ্টিমাইজ করা এবং কৃষকদের এক একর সময়ে আত্মবিশ্বাসের সাথে বেড়ে উঠতে সাহায্য করা।',
      'footer': 'প্রেসিস্প্রে · স্ক্রল, স্পর্শ এবং ট্যাপ করে অন্বেষণ করুন',
      'drawer_irrigation': 'সেচ নিয়ন্ত্রণ',
      'drawer_soil': 'মাটির স্বাস্থ্য',
      'drawer_weather': 'আবহাওয়া সতর্কতা',
      'drawer_market': 'বাজার দর',
      'profile_name': 'রমেশ শর্মা',
      'profile_sub': 'নাসিক · ৪.২ একর · আঙুর',
    },
    'mr': {
      'eyebrow': 'प्रेसिस्प्रे',
      'hero_title': 'बुद्धिमत्ता,\nशेतात जोपासलेली.',
      'hero_subtitle': 'प्रत्येक शेतात अचूकता — टिकाऊ, सुरक्षित आणि किफायतशीर.',
      'mission_tag': 'आमचे उद्दिष्ट',
      'mission_title': 'शेतासाठी तयार केलेले,\nऑफिससाठी नाही.',
      'mission1_title': 'टिकाऊपणा',
      'mission1_body': 'सौरऊर्जेवर चालणाऱ्या ऑप्टिमाइझ्ड फवारणीद्वारे रासायनिक अपव्यय आणि मातीचे प्रदूषण कमी करते.',
      'mission2_title': "शेतकऱ्याचे आरोग्य",
      'mission2_body': 'कीटकनाशकांच्या प्रवाहामुळे आणि परत येण्यामुळे होणाऱ्या विविध दीर्घकालीन आजारांपासून शेतकऱ्यांचे संरक्षण करते.',
      'mission3_title': 'अर्थशास्त्र आणि शेती',
      'mission3_body': 'कार्यक्षम, प्रवाहमुक्त फवारणीद्वारे खर्च कमी करते आणि पीक उत्पादन सुधारते.',
      'features_tag': 'वैशिष्ट्ये',
      'features_title': 'डेटा-आधारित,\nमातीतून उगवलेले.',
      'feature1_title': 'थेट क्षेत्र मॅपिंग डॅशबोर्ड',
      'feature1_body': 'अॅप्लिकेशनमध्ये नकाशावर फवारणी मार्ग दाखवते आणि जतन करते.',
      'feature2_title': 'हवामान आधारित फवारणी नियोजक',
      'feature2_body': 'प्रादेशिक हवामान अंदाजाच्या आधारे सुरक्षित फवारणीची वेळ ओळखते.',
      'feature3_title': 'रासायनिक मिश्रण कॅल्क्युलेटर',
      'feature3_body': 'आवश्यकतेनुसार शेतकऱ्यांना मिश्रण प्रमाणाचे मार्गदर्शन करते.',
      'feature4_title': 'फवारणी अहवाल',
      'feature4_body': 'फवारणी सत्राचा संपूर्ण अहवाल तयार करते.',
      'about_tag': 'आमच्याबद्दल',
      'about_title': 'तुमच्यासोबत तयार केलेले,\nशेतासाठी.',
      'about_body': 'प्रेसिस्प्रेची स्थापना अचूक शेती सुलभ आणि व्यावहारिक बनवण्यासाठी झाली. आम्ही अंदाजाची जागा डेटाने घेतो, एका सहज, शेतकरी-केंद्रित इंटरफेसद्वारे रिअल-टाइम माती आणि हवामान माहिती पुरवतो. संसाधनांचा वापर अनुकूल करणे आणि शेतकऱ्यांना एक एकर वेळी आत्मविश्वासाने वाढण्यास मदत करणे हे आमचे ध्येय आहे.',
      'footer': 'प्रेसिस्प्रे · स्क्रोल करा, स्पर्श करा आणि एक्सप्लोर करा',
      'drawer_irrigation': 'सिंचन नियंत्रण',
      'drawer_soil': 'मातीचे आरोग्य',
      'drawer_weather': 'हवामान सूचना',
      'drawer_market': 'बाजारभाव',
      'profile_name': 'रमेश शर्मा',
      'profile_sub': 'नाशिक · ४.२ एकर · द्राक्षे',
    },
  };

  static String t(String langCode, String key) {
    return _table[langCode]?[key] ?? _table['en']![key] ?? key;
  }
}

class LanguageController extends ChangeNotifier {
  String _code = 'en';
  String get code => _code;

  void setLanguage(String code) {
    if (_code == code) return;
    _code = code;
    notifyListeners();
  }

  String t(String key) => AppStrings.t(_code, key);
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'No LanguageScope found in context');
    return scope!.notifier!;
  }
}

const Map<String, String> kSupportedLanguages = {
  'en': 'English',
  'hi': 'हिंदी',
  'ta': 'தமிழ்',
  'bn': 'বাংলা',
  'mr': 'मराठी',
};

// ============================================================
// 1. LOGIN PAGE (unchanged)
// ============================================================

// ============================================================
// 1. LOGIN PAGE
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone    = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (phone.isEmpty || password.isEmpty) {
      _showMessage('Please enter phone number and password.');
      return;
    }
    setState(() => _loading = true);
    try {
      final db   = LocalDatabaseHelper.instance;
      final user = await db.verifyLocalLogin(phone, password);
      if (!mounted) return;
      if (user != null) {
        final int userId = user['id'] as int;
        UserSession().login(userId);
        final savedProfile = await db.getProfile(userId);
        final savedPlots   = await db.getPlots(userId);
        if (savedProfile != null) {
          ProfileStore().save(
            name:      savedProfile['name']?.toString()  ?? '',
            age:       savedProfile['age']?.toString()   ?? '',
            crops:     savedProfile['crops']?.toString() ?? '',
            plotNames: savedPlots.map((p) => p['plot_name']?.toString() ?? '').toList(),
            plotAreas: savedPlots.map((p) => p['area']?.toString()      ?? '').toList(),
          );
        } else {
          ProfileStore().save(name: '', age: '', crops: '', plotNames: [], plotAreas: []);
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AnimationScreen()),
        );
      } else {
        _showMessage('Invalid phone number or password.');
      }
    } catch (_) {
      if (mounted) _showMessage('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white.withOpacity(0.92),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.green.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.agriculture, size: 40, color: AppColors.green),
                      ),
                      const SizedBox(height: 22),
                      Text('Welcome Back', style: headingFont(size: 30, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Login to continue to PreciSpray',
                          textAlign: TextAlign.center,
                          style: bodyFont(size: 14, color: AppColors.textMuted)),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Contact Number', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.forestDeep,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(height: 22, width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('LOGIN',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: bodyFont(size: 13, color: AppColors.textMuted)),
                          GestureDetector(
                            onTap: _loading
                                ? null
                                : () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const RegisterPage())),
                            child: Text('Register',
                                style: bodyFont(size: 13, weight: FontWeight.w700,
                                    color: AppColors.green)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// 2. REGISTER PAGE
// ============================================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController           = TextEditingController();
  final TextEditingController _passwordController        = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final phone           = _phoneController.text.trim();
    final password        = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }
    if (phone.length < 10) {
      _showMessage('Please enter a valid contact number.');
      return;
    }
    if (password.length < 4) {
      _showMessage('Password must be at least 4 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      final userId = await LocalDatabaseHelper.instance.registerLocalUser(phone, password);
      if (!mounted) return;
      if (userId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully. Please login.')),
        );
        Navigator.pop(context);
      } else {
        _showMessage('An account with this phone number already exists.');
      }
    } catch (_) {
      if (mounted) _showMessage('Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white.withOpacity(0.92),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.green.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.person_add_alt_1, size: 38, color: AppColors.green),
                      ),
                      const SizedBox(height: 22),
                      Text('Create Account', style: headingFont(size: 30, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Register to start using PreciSpray',
                          textAlign: TextAlign.center,
                          style: bodyFont(size: 14, color: AppColors.textMuted)),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Contact Number', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration('Create Password', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _inputDecoration('Confirm Password', Icons.lock_reset_outlined).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.forestDeep,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(height: 22, width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('CREATE ACCOUNT',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: bodyFont(size: 13, color: AppColors.textMuted)),
                          GestureDetector(
                            onTap: _loading ? null : () => Navigator.pop(context),
                            child: Text('Login',
                                style: bodyFont(size: 13, weight: FontWeight.w700,
                                    color: AppColors.green)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({super.key});
  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  late VideoPlayerController _controller;
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();

    // Hard fallback: if the video never initializes, bail after 5 s.
    _fallbackTimer = Timer(const Duration(seconds: 5), _navigateToDashboard);

    _controller = VideoPlayerController.asset('assets/clean_modi.mp4');
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();

      // Now we know the exact duration â€” reset the fallback to
      // (actual duration + 1 s buffer) so it only fires if the video stalls.
      _fallbackTimer?.cancel();
      final videoDuration = _controller.value.duration;
      _fallbackTimer = Timer(videoDuration + const Duration(seconds: 1), _navigateToDashboard);
    }).catchError((error) {
      debugPrint('Video failed to initialize: $error');
      _navigateToDashboard();
    });
    _controller.addListener(_checkVideoEnd);
  }

  void _navigateToDashboard() {
    if (_navigated) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _checkVideoEnd() {
    if (_navigated) return;
    final value = _controller.value;
    if (value.isInitialized && value.position >= value.duration && !value.isPlaying) {
      _navigateToDashboard();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_checkVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: _controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ============================================================
// 3. DASHBOARD SCREEN OF PreciSpray content
// ============================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  bool _drawerOpen = false;
  late final LanguageController _languageController;

  // scroll-speed â€” ValueNotifier so only the painter rebuilds, not the whole tree
  final ScrollController _scrollCtrl = ScrollController();
  final ValueNotifier<double> _scrollSpeedNotifier = ValueNotifier(0.0);
  double _lastScrollOffset = 0.0;
  DateTime _lastScrollTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _languageController = LanguageController();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _languageController.dispose();
    _scrollCtrl.dispose();
    _scrollSpeedNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    final now    = DateTime.now();
    final dt     = now.difference(_lastScrollTime).inMilliseconds.clamp(16, 200).toDouble();
    final offset = _scrollCtrl.offset;
    final speed  = ((offset - _lastScrollOffset) / dt * 1000).abs();
    _lastScrollOffset = offset;
    _lastScrollTime   = now;
    _scrollSpeedNotifier.value = speed.clamp(0.0, 2000.0);
    // decay after 200ms â€” no setState, only notifier update
    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollSpeedNotifier.value = (_scrollSpeedNotifier.value * 0.5).clamp(0.0, 2000.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: _languageController,
      child: Scaffold(
        backgroundColor: AppColors.forestDeep,
        body: Stack(
          children: [
            // â”€â”€ layered background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _SceneBackground(speedNotifier: _staticSpeed),

            CustomScrollView(
              controller: _scrollCtrl,
              slivers: const [],
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _GlassTopBar(
                isOpen: _drawerOpen,
                onMenuTap: () => setState(() => _drawerOpen = !_drawerOpen),
              ),
            ),

            if (_drawerOpen)
              GestureDetector(
                onTap: () => setState(() => _drawerOpen = false),
                child: Container(color: Colors.black.withOpacity(0.45)),
              ),
            _SideDrawer(isOpen: _drawerOpen, onClose: () => setState(() => _drawerOpen = false)),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// Small helper: a Text widget that re-reads its string from
// LanguageScope every time the language changes.
// ----------------------------------------------------------
class _TranslatedText extends StatelessWidget {
  final String stringKey;
  final TextStyle Function(String translated) style;
  final TextAlign? textAlign;
  const _TranslatedText(this.stringKey, {required this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);
    final translated = lang.t(stringKey);
    return Text(translated, style: style(translated), textAlign: textAlign);
  }
}

// ----------------------------------------------------------
// Ambient glow blob
// ----------------------------------------------------------
class _GlowBlob extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  final Color color;
  final double opacity;
  const _GlowBlob({this.top, this.bottom, this.left, this.right, required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity),
            boxShadow: [BoxShadow(color: color.withOpacity(opacity), blurRadius: 80, spreadRadius: 40)],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// Glass top bar â€” language dropdown now actually switches
// the app's LanguageController instead of just local state.
// ----------------------------------------------------------
class _GlassTopBar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onMenuTap;

  const _GlassTopBar({
    required this.isOpen,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xD9061C14), Color(0x00061C14)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onMenuTap,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isOpen ? AppColors.cyan : AppColors.glassBorder),
                  ),
                  child: Icon(isOpen ? Icons.close : Icons.menu, color: Colors.white, size: 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.cyan),
                      alignment: Alignment.center,
                      child: const Text('A', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.forestDeep)),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: lang.code,
                      underline: const SizedBox(),
                      dropdownColor: AppColors.forest,
                      iconEnabledColor: Colors.white,
                      style: bodyFont(size: 14, weight: FontWeight.w600, color: Colors.white),
                      items: kSupportedLanguages.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (code) {
                        if (code != null) lang.setLanguage(code);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// Side drawer with profile + feature shortcuts
// ----------------------------------------------------------
class _SideDrawer extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  const _SideDrawer({required this.isOpen, required this.onClose});

  @override
  State<_SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<_SideDrawer> with SingleTickerProviderStateMixin {
  late final AnimationController _agriCtrl;

  @override
  void initState() {
    super.initState();
    ProfileStore().addListener(_onProfileChange);
    _agriCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  void _onProfileChange() => setState(() {});

  @override
  void dispose() {
    ProfileStore().removeListener(_onProfileChange);
    _agriCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileStore();
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      top: 0, bottom: 0,
      left: widget.isOpen ? 0 : -300,
      width: 300,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // â”€â”€ animated agri scene background (drawer-exclusive) â”€â”€
            Positioned.fill(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _agriCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _DrawerAgriPainter(_agriCtrl.value),
                  ),
                ),
              ),
            ),

            // â”€â”€ glass overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      AppColors.forest.withValues(alpha: 0.82),
                      AppColors.forestDeep.withValues(alpha: 0.94),
                    ],
                  ),
                  border: const Border(right: BorderSide(color: AppColors.glassBorder)),
                  boxShadow: widget.isOpen
                      ? [const BoxShadow(color: Colors.black54, blurRadius: 60, offset: Offset(30, 0))]
                      : [],
                ),
              ),
            ),

            // â”€â”€ content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 70, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // profile summary
                    if (profile.hasProfile) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                              style: headingFont(size: 18, color: AppColors.green),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(profile.name,
                                style: bodyFont(size: 14, weight: FontWeight.w700, color: Colors.white),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (profile.crops.isNotEmpty)
                              Text(profile.crops,
                                  style: bodyFont(size: 12, color: AppColors.textMuted),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (profile.plotAreas.isNotEmpty)
                              Text(
                                List.generate(profile.plotAreas.length, (i) {
                                  final n = i < profile.plotNames.length && profile.plotNames[i].trim().isNotEmpty
                                      ? profile.plotNames[i].trim() : 'Plot ${i + 1}';
                                  final a = profile.plotAreas[i].trim();
                                  return a.isNotEmpty ? '$n Â· ${a} ac' : n;
                                }).join('  |  '),
                                style: bodyFont(size: 11, color: AppColors.green),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                              ),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(color: AppColors.glassBorder, height: 1),
                    const SizedBox(height: 22),
                    _DrawerFeature(icon: Icons.person, color: AppColors.green, labelKey: 'drawer_profile',
                      onTap: () { widget.onClose(); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); }),
                    const SizedBox(height: 14),
                    _DrawerFeature(icon: Icons.play_circle_outline, color: AppColors.cyan, labelKey: 'drawer_tutorial',
                      onTap: () { widget.onClose(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutorial — coming soon!'))); }),
                    const SizedBox(height: 14),
                    _DrawerFeature(icon: Icons.grid_view_rounded, color: AppColors.orange, labelKey: 'drawer_features',
                      onTap: () { widget.onClose(); Navigator.push(context, MaterialPageRoute(builder: (_) => const FeaturesScreen())); }),
                    const SizedBox(height: 14),
                    _DrawerFeature(icon: Icons.info_outline, color: AppColors.yellow, labelKey: 'drawer_about',
                      onTap: () { widget.onClose(); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())); }),

                    const Spacer(),

                    // â”€â”€ drawer-only animated agri widget â”€â”€
                    _DrawerAgriWidget(controller: _agriCtrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerFeature extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String labelKey;
  final VoidCallback? onTap;
  const _DrawerFeature({required this.icon, required this.color, required this.labelKey, this.onTap});

  @override
  State<_DrawerFeature> createState() => _DrawerFeatureState();
}

class _DrawerFeatureState extends State<_DrawerFeature> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp: (_) => setState(() => _hover = false),
      onTapCancel: () => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hover ? AppColors.glass : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hover ? AppColors.glassBorder : Colors.transparent),
        ),
        transform: Matrix4.translationValues(_hover ? 4 : 0, 0, 0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _hover ? widget.color : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _hover ? [BoxShadow(color: widget.color, blurRadius: 18)] : [],
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, size: 18, color: _hover ? AppColors.forestDeep : Colors.white),
            ),
            const SizedBox(width: 14),
            Text(lang.t(widget.labelKey), style: bodyFont(size: 14, weight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Drawer-exclusive agri animation widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// Bottom widget inside drawer: animated seedling growing
class _DrawerAgriWidget extends StatelessWidget {
  final AnimationController controller;
  const _DrawerAgriWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.15)),
        ),
        child: CustomPaint(
          painter: _DrawerGardenPainter(controller.value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(children: [
              const SizedBox(width: 70),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Fields growing', style: bodyFont(size: 10, color: AppColors.green)),
                Text('PreciSpray active', style: bodyFont(size: 11, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// Draws animated mini wheat/seedling stalks + a tiny drone in the drawer bottom strip
class _DrawerGardenPainter extends CustomPainter {
  final double t;
  _DrawerGardenPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = AppColors.green.withValues(alpha: 0.7)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leafPaint = Paint()
      ..color = AppColors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // 5 wheat stalks with swaying animation
    final stalks = [0.06, 0.12, 0.18, 0.24, 0.30];
    for (int i = 0; i < stalks.length; i++) {
      final x = stalks[i] * size.width;
      final sway = math.sin(t * 2 * math.pi + i * 0.8) * 3;
      final h = size.height * (0.55 + (i % 3) * 0.08);
      canvas.drawLine(Offset(x, size.height), Offset(x + sway, size.height - h), stemPaint);
      // leaf
      final leafPath = Path()
        ..moveTo(x + sway, size.height - h * 0.6)
        ..quadraticBezierTo(x + sway + 8, size.height - h * 0.7, x + sway + 6, size.height - h * 0.5)
        ..close();
      canvas.drawPath(leafPath, leafPaint);
      // seed head
      canvas.drawCircle(Offset(x + sway, size.height - h), 2.5,
          Paint()..color = AppColors.yellow.withValues(alpha: 0.8));
    }

    // tiny drone flying across strip
    final dX = (t * size.width * 1.3) % (size.width + 20) - 10;
    final dY = size.height * 0.25 + math.sin(t * math.pi * 4) * 4;
    final dp = Paint()
      ..color = AppColors.cyan
      ..style = PaintingStyle.fill;
    // body
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(dX, dY), width: 10, height: 5),
      const Radius.circular(2),
    ), dp);
    // propeller hint
    canvas.drawLine(Offset(dX - 7, dY - 1), Offset(dX - 3, dY - 1),
        Paint()..color = AppColors.cyan.withValues(alpha: 0.7)..strokeWidth = 1.5);
    canvas.drawLine(Offset(dX + 3, dY - 1), Offset(dX + 7, dY - 1),
        Paint()..color = AppColors.cyan.withValues(alpha: 0.7)..strokeWidth = 1.5);
  }

  @override bool shouldRepaint(covariant _DrawerGardenPainter o) => o.t != t;
}

// Full drawer background scene: earthy rolling hills + floating pollen dots
class _DrawerAgriPainter extends CustomPainter {
  final double t;
  _DrawerAgriPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: const [Color(0xFF0B3D2E), Color(0xFF06241A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // rolling field bottom
    final fp = Paint()..color = const Color(0xFF0D4030)..style = PaintingStyle.fill;
    final fp2 = Paint()..color = const Color(0xFF0A3528)..style = PaintingStyle.fill;
    final fieldPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.65 + math.sin(t * math.pi) * 6,
          size.width * 0.6, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.67, size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fieldPath, fp);

    final fieldPath2 = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.80 + math.sin(t * math.pi + 1) * 4,
          size.width * 0.7, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.81, size.width, size.height * 0.84)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fieldPath2, fp2);

    // floating pollen/spore dots
    final pollenSeeds = [
      [0.15, 0.3, 0.0], [0.4, 0.2, 0.4], [0.7, 0.4, 0.7],
      [0.25, 0.55, 0.2], [0.6, 0.6, 0.9], [0.85, 0.25, 0.5],
    ];
    for (final s in pollenSeeds) {
      final phase = (t + s[2]) % 1.0;
      final x = s[0] * size.width + math.sin(phase * math.pi * 2) * 6;
      final y = size.height * (s[1] - phase * 0.15);
      if (y < 0 || y > size.height) continue;
      canvas.drawCircle(
        Offset(x, y),
        2.0,
        Paint()
          ..color = AppColors.green.withValues(alpha: math.sin(phase * math.pi) * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override bool shouldRepaint(covariant _DrawerAgriPainter o) => o.t != t;
}

// ============================================================
// PROFILE SCREEN â€” reached from the drawer's "Profile" button.
// Background kept consistent with the dashboard (same gradient
// + glow blobs) so it doesn't feel like a different app.
// ============================================================
// PROFILE STORE â€” simple in-memory store for MVP.
// Holds the last submitted profile so the drawer can display it.
// ============================================================

// ============================================================
// CURRENT USER SESSION
// Stores the unique SQLite user ID of the currently logged-in user.
// ============================================================
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  int? userId;
  bool get isLoggedIn => userId != null;
  void login(int id) => userId = id;
  void logout() => userId = null;
}

class ProfileStore extends ChangeNotifier {
  static final ProfileStore _instance = ProfileStore._internal();
  factory ProfileStore() => _instance;
  ProfileStore._internal();

  String name   = '';
  String age    = '';
  String crops  = '';
  List<String> plotAreas = [];
  List<String> plotNames = [];

  bool get hasProfile => name.trim().isNotEmpty;

  void save({
    required String name,
    required String age,
    required String crops,
    required List<String> plotAreas,
    required List<String> plotNames,
  }) {
    this.name      = name.trim();
    this.age       = age.trim();
    this.crops     = crops.trim();
    this.plotAreas = plotAreas;
    this.plotNames = plotNames;
    notifyListeners();
  }
}

// ============================================================
// PROFILE SCREEN
// ============================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _PlotEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cropsController = TextEditingController();
  final List<_PlotEntry> _plots = [_PlotEntry()];

  @override
  void initState() {
    super.initState();
    // Pre-fill from store if a profile was already saved
    final store = ProfileStore();
    if (store.hasProfile) {
      _nameController.text  = store.name;
      _ageController.text   = store.age;
      _cropsController.text = store.crops;
      if (store.plotAreas.isNotEmpty) {
        _plots.clear();
        for (int i = 0; i < store.plotAreas.length; i++) {
          final entry = _PlotEntry();
          entry.nameController.text = i < store.plotNames.length ? store.plotNames[i] : '';
          entry.areaController.text = store.plotAreas[i];
          _plots.add(entry);
        }
      }
    }
  }

  void _addPlot() {
    setState(() => _plots.add(_PlotEntry()));
  }

  void _removePlot(int index) {
    if (_plots.length == 1) return; // always keep at least one plot tab
    setState(() {
      _plots[index].nameController.dispose();
      _plots[index].areaController.dispose();
      _plots.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    final name  = _nameController.text;
    final age   = _ageController.text;
    final crops = _cropsController.text;

    final userId = UserSession().userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    final db = LocalDatabaseHelper.instance;
    await db.saveProfile(userId, name, age, crops);
    await db.clearAllPlots(userId);
    for (final plot in _plots) {
      final plotName = plot.nameController.text.trim();
      final plotArea = plot.areaController.text.trim();
      if (plotArea.isNotEmpty) {
        await db.savePlot(userId, plotName, plotArea);
      }
    }

    ProfileStore().save(
      name:      name,
      age:       age,
      crops:     crops,
      plotNames: _plots.map((p) => p.nameController.text).toList(),
      plotAreas: _plots.map((p) => p.areaController.text).toList(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
      Navigator.pop(context);
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cropsController.dispose();
    for (final plot in _plots) {
      plot.nameController.dispose();
      plot.areaController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -1.0),
                radius: 1.4,
                colors: [Color(0xFF103D2C), Color(0xFF07261C), Color(0xFF051A13)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          const _GlowBlob(top: -120, right: -100, size: 420, color: AppColors.cyan, opacity: 0.30),
          const _GlowBlob(bottom: 80, left: -140, size: 380, color: AppColors.orange, opacity: 0.30),
          const _GlowBlob(top: 320, right: 30, size: 300, color: AppColors.yellow, opacity: 0.15),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Your Profile', style: headingFont(size: 26)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _ProfileLabel('Name'),
                  const SizedBox(height: 8),
                  _ProfileTextField(controller: _nameController, hint: 'Enter your name'),
                  const SizedBox(height: 20),

                  _ProfileLabel('Age'),
                  const SizedBox(height: 8),
                  _ProfileTextField(controller: _ageController, hint: 'Enter your age', keyboardType: TextInputType.number),
                  const SizedBox(height: 20),

                  _ProfileLabel('Crops grown'),
                  const SizedBox(height: 8),
                  _ProfileTextField(controller: _cropsController, hint: 'e.g. Grapes, Wheat'),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProfileLabel('Plots'),
                      GestureDetector(
                        onTap: _addPlot,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AppColors.green.withOpacity(0.5), blurRadius: 16)],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, color: AppColors.forestDeep, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  ...List.generate(_plots.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlotTab(
                        index: i,
                        nameController: _plots[i].nameController,
                        areaController: _plots[i].areaController,
                        onRemove: _plots.length > 1 ? () => _removePlot(i) : null,
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _handleSubmit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.green, AppColors.cyan]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColors.green.withOpacity(0.35), blurRadius: 24)],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Submit',
                          style: bodyFont(size: 16, weight: FontWeight.w700, color: AppColors.forestDeep),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  final String text;
  const _ProfileLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: bodyFont(size: 14, weight: FontWeight.w700, color: AppColors.textMuted).copyWith(letterSpacing: 0.5));
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const _ProfileTextField({required this.controller, required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: bodyFont(size: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: bodyFont(size: 15, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// One "tab" for a plot â€” its number/label plus an area input.
/// Tapping + above adds another one of these; each keeps its own
/// area value independently.
class _PlotTab extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController areaController;
  final VoidCallback? onRemove;
  const _PlotTab({
    required this.index,
    required this.nameController,
    required this.areaController,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withOpacity(0.5)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.grass, size: 18, color: AppColors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editable plot name
                TextField(
                  controller: nameController,
                  style: bodyFont(size: 14, weight: FontWeight.w700, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Plot ${index + 1} name',
                    hintStyle: bodyFont(size: 14, weight: FontWeight.w700, color: AppColors.textMuted),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 6),
                // Editable area
                TextField(
                  controller: areaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: bodyFont(size: 13, color: AppColors.textBody),
                  decoration: InputDecoration(
                    hintText: 'Area (in acres)',
                    hintStyle: bodyFont(size: 13, color: AppColors.textMuted),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// FEATURES SCREEN
// ============================================================
class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: LanguageController(),
      child: _FeaturesScreenBody(),
    );
  }
}

class _FeaturesScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: Stack(
        children: [
          _SceneBackground(speedNotifier: _staticSpeed),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 22, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text('Features',
                          style: headingFont(size: 22, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHead(tagKey: 'features_tag', titleKey: 'features_title'),
                        const SizedBox(height: 18),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.75,
                          children: [
                            _FeatureCard(
                              icon: Icons.map_outlined,
                              color: const Color(0xFF7EC87A), // light green
                              titleKey: 'feature1_title',
                              bodyKey: 'feature1_body',
                              previewChild: const _MapPreview(),
                              onTap: (ctx) => Navigator.push(ctx,
                                  MaterialPageRoute(builder: (_) => const MapScreen())),
                            ),
                            _FeatureCard(
                              icon: Icons.cloud_queue,
                              color: const Color(0xFF7AC8E8), // sky blue
                              titleKey: 'feature2_title',
                              bodyKey: 'feature2_body',
                              previewChild: const _WeatherPreview(),
                              onTap: (ctx) => Navigator.push(ctx,
                                  MaterialPageRoute(builder: (_) => const WeatherScreen())),
                            ),
                            _FeatureCard(
                              icon: Icons.summarize_outlined,
                              color: const Color(0xFFD4A843), // warm yellow report
                              titleKey: 'feature4_title',
                              bodyKey: 'feature4_body',
                              previewChild: const _ReportPreview(),
                              onTap: (ctx) => Navigator.push(ctx,
                                  MaterialPageRoute(builder: (_) => const SprayReportScreen())),
                            ),
                            _FeatureCard(
                              icon: Icons.hub_outlined,
                              color: const Color(0xFF3A5FCD), // ultramarine blue
                              titleKey: 'feature5_title',
                              bodyKey: 'feature5_body',
                              previewChild: const _NetworkingPreview(),
                              onTap: (ctx) => Navigator.push(ctx,
                                  MaterialPageRoute(builder: (_) => const NetworkingScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: _TranslatedText(
                            'footer',
                            style: (t) => bodyFont(size: 12, color: AppColors.textFooter),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shared static speed notifier for screens that don't scroll
final ValueNotifier<double> _staticSpeed = ValueNotifier(0.0);

// ============================================================
// ABOUT US SCREEN
// ============================================================
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: LanguageController(),
      child: _AboutUsScreenBody(),
    );
  }
}

class _AboutUsScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: Stack(
        children: [
          _SceneBackground(speedNotifier: _staticSpeed),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 22, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text('About Us',
                          style: headingFont(size: 22, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHead(tagKey: 'mission_tag', titleKey: 'mission_title'),
                        const SizedBox(height: 18),
                        _ScrollReveal(
                          index: 0,
                          child: _MissionCard(
                            iconPainter: const _SustainabilityIconPainter(),
                            glow: AppColors.green,
                            titleKey: 'mission1_title',
                            bodyKey: 'mission1_body',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ScrollReveal(
                          index: 1,
                          child: _MissionCard(
                            iconPainter: const _HealthIconPainter(),
                            glow: AppColors.cyan,
                            titleKey: 'mission2_title',
                            bodyKey: 'mission2_body',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ScrollReveal(
                          index: 2,
                          child: _MissionCard(
                            iconPainter: const _EconomicsIconPainter(),
                            glow: AppColors.yellow,
                            titleKey: 'mission3_title',
                            bodyKey: 'mission3_body',
                          ),
                        ),
                        const SizedBox(height: 30),
                        const _SectionHead(tagKey: 'about_tag', titleKey: 'about_title'),
                        const SizedBox(height: 18),
                        const _AboutBox(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------
// â•â• NEW DYNAMIC BACKGROUND WIDGETS â•â•
// ----------------------------------------------------------

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// 1. Animated farm night-scene background
//    - Night sky with twinkling stars
//    - Slowly drifting clouds (speed x scroll intensity)
//    - Rolling hills + mountains silhouette
//    - Farmhouse with pulsing warm window light
//    - Three animated windmills (blades spinning)
//    - Foreground wheat/grass swaying (speed x scroll)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _SceneBackground extends StatefulWidget {
  final ValueNotifier<double> speedNotifier;
  const _SceneBackground({super.key, required this.speedNotifier});

  @override
  State<_SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<_SceneBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _master;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        // AnimatedBuilder on master clock drives smooth animation.
        // ValueListenableBuilder wraps it so scroll-speed changes
        // reach the painter without rebuilding the dashboard tree.
        child: AnimatedBuilder(
          animation: _master,
          builder: (_, __) => ValueListenableBuilder<double>(
            valueListenable: widget.speedNotifier,
            builder: (_, speed, __) => CustomPaint(
              painter: _FarmScenePainter(
                t: _master.value,
                scrollSpeed: speed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FarmScenePainter extends CustomPainter {
  final double t;           // 0..1 repeating master time
  final double scrollSpeed; // px/s â€“ drives cloud + grass speed

  const _FarmScenePainter({required this.t, required this.scrollSpeed});

  // normalised scroll multiplier: 0 = idle, 1 = full blast (â‰¥800 px/s)
  double get _sm => (scrollSpeed / 800.0).clamp(0.0, 1.0);

  // â”€â”€ Sky â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawSky(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF060F2A), // deep midnight navy
          Color(0xFF0B1E4A), // rich blue
          Color(0xFF0F2E5E), // saturated mid blue
          Color(0xFF0A2540), // deep teal horizon
        ],
        stops: const [0.0, 0.40, 0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
  }

  // â”€â”€ Stars â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawStars(Canvas canvas, double w, double h) {
    final starData = _starPositions(w, h * 0.55);
    for (int i = 0; i < starData.length; i++) {
      final s      = starData[i];
      final phase  = (t * 3.0 + i * 0.37) % 1.0;
      final bright = 0.5 + 0.5 * _sin01(phase);
      canvas.drawCircle(
        Offset(s[0], s[1]), s[2],
        Paint()
          ..color = Color.fromRGBO(210, 230, 255, bright)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
      );
    }
  }

  // â”€â”€ Moon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawMoon(Canvas canvas, double w, double h) {
    final cx = w * 0.80;
    final cy = h * 0.09;
    canvas.drawCircle(Offset(cx, cy), 32,
        Paint()..color = const Color(0x33B8D8FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
    canvas.drawCircle(Offset(cx, cy), 15,
        Paint()..color = const Color(0xFFDCEEFF));
    // crescent shadow
    canvas.drawCircle(Offset(cx + 6, cy - 4), 12,
        Paint()..color = const Color(0xFF0B1E4A));
  }

  // â”€â”€ Clouds â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawClouds(Canvas canvas, double w, double h) {
    final speed = 0.055 + _sm * 0.20;
    // Each cloud has a fixed phase offset (0.0 – 0.75) spread evenly across
    // the 0→1 cycle so they never all wrap at the same moment.
    // Position maps 0→1 to (-cloudW) → (w + cloudW) so the cloud is fully
    // off-screen on both sides before it "teleports" — making the loop
    // completely invisible and smooth.
    final clouds = [
      // [phaseOffset, yFrac, widthFrac, alpha]
      [0.00, 0.10, 0.24, 0.72],
      [0.25, 0.06, 0.18, 0.58],
      [0.50, 0.13, 0.22, 0.65],
      [0.75, 0.18, 0.15, 0.50],
    ];
    for (final c in clouds) {
      final phase = (c[0] + t * speed) % 1.0; // always 0..1, seamless
      final cx = (phase * (w + c[2] * w * 2)) - c[2] * w; // enters from left edge, exits right
      _drawCloud(canvas, cx, c[1] * h, c[2] * w, c[3]);
    }
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double cw, double alpha) {
    // Rich blue-white clouds matching reference image
    final paint = Paint()..color = Color.fromRGBO(160, 195, 235, alpha * 0.70);
    final ch = cw * 0.40;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: cw, height: ch), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - cw * 0.28, cy + ch * 0.08), width: cw * 0.54, height: ch * 0.82), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + cw * 0.26, cy + ch * 0.10), width: cw * 0.50, height: ch * 0.78), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - cw * 0.04, cy - ch * 0.34), width: cw * 0.44, height: ch * 0.72), paint);
  }

  // â”€â”€ Mountains â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawMountains(Canvas canvas, double w, double h) {
    // far mountains â€” rich slate-blue like reference
    final farPaint = Paint()..color = const Color(0xFF183A6B);
    final farPath  = Path()
      ..moveTo(0, h * 0.52)
      ..cubicTo(w * 0.10, h * 0.28, w * 0.22, h * 0.36, w * 0.30, h * 0.44)
      ..cubicTo(w * 0.38, h * 0.20, w * 0.50, h * 0.30, w * 0.58, h * 0.44)
      ..cubicTo(w * 0.65, h * 0.24, w * 0.78, h * 0.32, w * 0.85, h * 0.46)
      ..lineTo(w, h * 0.50)..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(farPath, farPaint);

    // snow-cap hints on peaks
    final snowPaint = Paint()..color = const Color(0xFF2A5A9A);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.46, h * 0.225), width: w * 0.08, height: h * 0.04), snowPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.74, h * 0.26), width: w * 0.06, height: h * 0.03), snowPaint);

    // closer ridge â€” darker, richer blue-green
    final midPaint = Paint()..color = const Color(0xFF112F55);
    final midPath  = Path()
      ..moveTo(0, h * 0.60)
      ..cubicTo(w * 0.12, h * 0.42, w * 0.20, h * 0.50, w * 0.28, h * 0.56)
      ..cubicTo(w * 0.36, h * 0.34, w * 0.44, h * 0.44, w * 0.52, h * 0.57)
      ..cubicTo(w * 0.62, h * 0.36, w * 0.72, h * 0.46, w * 0.80, h * 0.55)
      ..cubicTo(w * 0.88, h * 0.40, w * 0.94, h * 0.48, w, h * 0.54)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(midPath, midPaint);
  }

  // â”€â”€ Rolling hills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawHills(Canvas canvas, double w, double h) {
    // hill 1 â€” teal-green saturated
    final p1 = Paint()..color = const Color(0xFF0D2E4A);
    final path1 = Path()
      ..moveTo(0, h * 0.67)
      ..cubicTo(w * 0.20, h * 0.55, w * 0.40, h * 0.62, w * 0.55, h * 0.68)
      ..cubicTo(w * 0.70, h * 0.56, w * 0.85, h * 0.64, w, h * 0.66)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path1, p1);

    // hill 2 â€” darker, closer
    final p2 = Paint()..color = const Color(0xFF091F38);
    final path2 = Path()
      ..moveTo(0, h * 0.75)
      ..cubicTo(w * 0.15, h * 0.65, w * 0.32, h * 0.70, w * 0.48, h * 0.73)
      ..cubicTo(w * 0.62, h * 0.63, w * 0.78, h * 0.70, w, h * 0.71)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path2, p2);

    // bump/mound under left farmhouse like the reference image
    final moundPaint = Paint()..color = const Color(0xFF0A2440);
    final moundPath = Path()
      ..moveTo(w * 0.05, h * 0.76)
      ..cubicTo(w * 0.10, h * 0.60, w * 0.22, h * 0.58, w * 0.28, h * 0.70)
      ..cubicTo(w * 0.30, h * 0.75, w * 0.26, h * 0.78, w * 0.20, h * 0.78)
      ..lineTo(0, h * 0.78)..close();
    canvas.drawPath(moundPath, moundPaint);
  }

  // â”€â”€ Trees (round blob style from reference) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawTrees(Canvas canvas, double w, double h) {
    final treePaint = Paint()..color = const Color(0xFF0C2840);
    final treePositions = [
      [0.08, 0.70, 0.035],
      [0.12, 0.71, 0.028],
      [0.74, 0.68, 0.030],
      [0.79, 0.69, 0.025],
      [0.84, 0.67, 0.032],
    ];
    for (final tp in treePositions) {
      final tx = tp[0] * w;
      final ty = tp[1] * h;
      final tr = tp[2] * w;
      // trunk
      canvas.drawRect(Rect.fromLTWH(tx - tr * 0.15, ty, tr * 0.30, tr * 0.6),
          Paint()..color = const Color(0xFF081828));
      // canopy blob
      canvas.drawOval(Rect.fromCenter(center: Offset(tx, ty - tr * 0.3), width: tr * 2.0, height: tr * 1.6), treePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(tx - tr * 0.6, ty - tr * 0.1), width: tr * 1.4, height: tr * 1.2), treePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(tx + tr * 0.6, ty - tr * 0.1), width: tr * 1.4, height: tr * 1.2), treePaint);
    }
  }

  // â”€â”€ Farmhouses (left small, right larger â€” matches reference)
  void _drawFarmhouse(Canvas canvas, double w, double h) {
    _drawHouse(canvas, w * 0.16, h * 0.68, w * 0.09, h, isLarge: false);
    _drawHouse(canvas, w * 0.80, h * 0.66, w * 0.13, h, isLarge: true);
  }

  void _drawHouse(Canvas canvas, double hx, double hy, double hw, double h,
      {required bool isLarge}) {
    final hh = hw * 0.80;
    final wallPaint = Paint()..color = const Color(0xFF0E2240);
    canvas.drawRect(Rect.fromLTWH(hx - hw / 2, hy - hh, hw, hh), wallPaint);

    // roof (darker blue-slate)
    final roofPaint = Paint()..color = const Color(0xFF091830);
    final roofPath = Path()
      ..moveTo(hx - hw * 0.60, hy - hh)
      ..lineTo(hx,              hy - hh * 1.50)
      ..lineTo(hx + hw * 0.60,  hy - hh)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // solar panels on roof (small detail)
    canvas.drawRect(
      Rect.fromLTWH(hx - hw * 0.25, hy - hh * 1.28, hw * 0.5, hh * 0.18),
      Paint()..color = const Color(0xFF1A3A60),
    );

    // pulsing warm window light
    final winBright = 0.60 + 0.40 * _sin01((t * 0.7 + (isLarge ? 0.5 : 0.1)) % 1.0);
    final winGlow   = Color.fromRGBO(255, 195, 60, winBright);
    final glowPaint = Paint()
      ..color = Color.fromRGBO(255, 160, 30, winBright * 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final offsets = isLarge
        ? [Offset(hx - hw * 0.22, hy - hh * 0.55), Offset(hx + hw * 0.22, hy - hh * 0.55),
           Offset(hx - hw * 0.22, hy - hh * 0.22), Offset(hx + hw * 0.22, hy - hh * 0.22)]
        : [Offset(hx - hw * 0.18, hy - hh * 0.52), Offset(hx + hw * 0.18, hy - hh * 0.52)];

    for (final wc in offsets) {
      canvas.drawRect(Rect.fromCenter(center: wc, width: hw * 0.22, height: hh * 0.22), glowPaint);
      canvas.drawRect(Rect.fromCenter(center: wc, width: hw * 0.17, height: hh * 0.17),
          Paint()..color = winGlow);
    }

    // door
    canvas.drawRect(
      Rect.fromCenter(center: Offset(hx, hy - hh * 0.13), width: hw * 0.22, height: hh * 0.27),
      Paint()..color = const Color(0xFF162840),
    );
  }

  // â”€â”€ Windmills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawWindmills(Canvas canvas, double w, double h) {
    final baseAngle = t * math.pi * 2 * 2.5;
    final extraSpin = _sm * math.pi * 2 * 4;
    final angle     = baseAngle + extraSpin;

    // 3 windmills â€” sizes and positions match reference
    final mills = [
      [0.30, 0.68, 0.072], // left large
      [0.48, 0.63, 0.055], // centre tall
      [0.60, 0.67, 0.042], // right smaller
    ];
    for (int i = 0; i < mills.length; i++) {
      _drawWindmill(canvas, mills[i][0] * w, mills[i][1] * h,
          mills[i][2] * w, angle + i * math.pi * 0.66);
    }
  }

  void _drawWindmill(Canvas canvas, double cx, double base, double scale, double angle) {
    final mast = scale * 2.8;
    // mast â€” slightly tapered
    canvas.drawLine(Offset(cx, base), Offset(cx, base - mast),
        Paint()
          ..color = const Color(0xFF2A5080)
          ..strokeWidth = scale * 0.20
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
    // hub
    canvas.drawCircle(Offset(cx, base - mast), scale * 0.22,
        Paint()..color = const Color(0xFF3A6A9A));
    // 3 blades
    for (int b = 0; b < 3; b++) {
      final ba   = angle + b * math.pi * 2 / 3;
      final tipX = cx + math.cos(ba) * scale * 1.15;
      final tipY = (base - mast) + math.sin(ba) * scale * 1.15;
      final cp1x = cx + math.cos(ba + 0.5) * scale * 0.45;
      final cp1y = (base - mast) + math.sin(ba + 0.5) * scale * 0.45;
      final bladePath = Path()
        ..moveTo(cx, base - mast)
        ..quadraticBezierTo(cp1x, cp1y, tipX, tipY)
        ..close();
      canvas.drawPath(bladePath,
          Paint()..color = const Color(0xFF2A5080)..style = PaintingStyle.fill);
    }
  }

  // â”€â”€ Foreground field stripes (ploughed rows from reference)
  void _drawFieldRows(Canvas canvas, double w, double h) {
    final rowPaint = Paint()
      ..color = const Color(0xFF0A2035)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final count = 14;
    for (int i = 0; i < count; i++) {
      final yFrac = 0.80 + i * 0.022;
      if (yFrac > 1.0) break;
      final y = yFrac * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), rowPaint);
    }
  }

  // â”€â”€ Grass / wheat foreground â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawGrass(Canvas canvas, double w, double h) {
    final swaySpeed = 1.0 + _sm * 8.0;
    final swayAmp   = 2.5 + _sm * 12.0;
    final baseY     = h * 0.82;

    // back layer
    for (int i = 0; i < 55; i++) {
      final xf     = i / 55.0;
      final x      = xf * w;
      final phase  = xf * math.pi * 6;
      final sway   = math.sin(t * math.pi * 2 * swaySpeed + phase) * swayAmp;
      final bladeH = h * (0.065 + _hash(i * 37 + 1) % 30 / 1000);
      final tipX   = x + math.sin(sway * math.pi / 180) * bladeH * 0.6;
      // rich teal-green colour
      final g = 55 + (i * 9 % 35);
      canvas.drawLine(Offset(x, baseY), Offset(tipX, baseY - bladeH),
          Paint()
            ..color = Color.fromRGBO(8, g, 75, 0.90)
            ..strokeWidth = 1.4 + (_hash(i * 113 + 5) % 10) / 10.0
            ..strokeCap = StrokeCap.round);
    }

    // front layer â€” denser, darker teal
    for (int i = 0; i < 90; i++) {
      final xf    = i / 90.0;
      final x     = xf * w;
      final phase = xf * math.pi * 8 + 1.2;
      final sway  = math.sin(t * math.pi * 2 * swaySpeed + phase) * swayAmp * 1.4;
      final bladeH = h * (0.11 + _hash(i * 53 + 9) % 50 / 1000);
      final tipX   = x + math.sin(sway * math.pi / 180) * bladeH * 0.7;
      canvas.drawLine(Offset(x, baseY + h * 0.05), Offset(tipX, baseY + h * 0.05 - bladeH),
          Paint()
            ..color = const Color(0xCC0A3060)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round);
    }
  }

  // Semi-transparent dark overlay so content text stays readable
  // Transparency set to 70% (alpha 0.30 darkening = 70% see-through)
  void _drawContentOverlay(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0x4D040C1A), // ~30% dark = 70% transparent
    );
  }

  // â”€â”€ Paint entry point â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawSky(canvas, w, h);
    _drawStars(canvas, w, h);
    _drawMoon(canvas, w, h);
    _drawClouds(canvas, w, h);
    _drawMountains(canvas, w, h);
    _drawHills(canvas, w, h);
    _drawTrees(canvas, w, h);
    _drawFarmhouse(canvas, w, h);
    _drawWindmills(canvas, w, h);
    _drawFieldRows(canvas, w, h);
    _drawGrass(canvas, w, h);
    _drawContentOverlay(canvas, w, h);
  }

  @override
  bool shouldRepaint(covariant _FarmScenePainter old) => true;

  // ── Helper utilities ───────────────────────────────────
  List<List<double>> _starPositions(double w, double h) {
    final list = <List<double>>[];
    for (int i = 0; i < 60; i++) {
      final xf = _hash(i * 1731 + 7)   % w;
      final yf = _hash(i * 2357 + 13)  % h;
      final rf = 0.5 + (_hash(i * 991 + 3) % 10) / 10.0 * 1.2;
      list.add([xf, yf, rf]);
    }
    return list;
  }

  double _hash(int n) =>
      ((n * 1664525 + 1013904223) & 0x7FFFFFFF).toDouble();

  double _sin01(double x) => (math.sin(x * math.pi * 2) + 1) / 2;
}

// 2. Hero scene overlay painter (shimmering crop rows + layered fields)
class _HeroScenePainter extends CustomPainter {
  final double shimmer; // 0..1
  _HeroScenePainter(this.shimmer);

  @override
  void paint(Canvas canvas, Size size) {
    // foreground grass strip
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, const Color(0x3304120D)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.80, size.width, size.height * 0.20));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.80, size.width, size.height * 0.20), grassPaint);

    // shimmer light band across crop field
    final shimmerX = -size.width * 0.3 + shimmer * size.width * 1.6;
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Colors.transparent, const Color(0x1AFFFFFF), Colors.transparent],
      ).createShader(Rect.fromLTWH(shimmerX, 0, size.width * 0.3, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant _HeroScenePainter old) => old.shimmer != shimmer;
}

// 3. Animated drone widget (pure widget, no assets needed)
class _DroneWidget extends StatelessWidget {
  const _DroneWidget();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(52, 30), painter: _DronePainter());
  }
}

class _DronePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = const Color(0xFFCDEBD8)
      ..style = PaintingStyle.fill;
    final propPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = const Color(0x554ADE80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // glow
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 18, glowPaint);

    // body â€” rounded rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.35, size.width * 0.50, size.height * 0.30),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // 4 arms
    final armPaint = Paint()..color = const Color(0xFF9DC4B0)..strokeWidth = 2..style = PaintingStyle.stroke;
    // top-left arm
    canvas.drawLine(Offset(size.width * 0.30, size.height * 0.40),
        Offset(size.width * 0.10, size.height * 0.18), armPaint);
    // top-right arm
    canvas.drawLine(Offset(size.width * 0.70, size.height * 0.40),
        Offset(size.width * 0.90, size.height * 0.18), armPaint);
    // bottom-left arm
    canvas.drawLine(Offset(size.width * 0.30, size.height * 0.60),
        Offset(size.width * 0.10, size.height * 0.82), armPaint);
    // bottom-right arm
    canvas.drawLine(Offset(size.width * 0.70, size.height * 0.60),
        Offset(size.width * 0.90, size.height * 0.82), armPaint);

    // 4 propellers
    for (final center in [
      Offset(size.width * 0.10, size.height * 0.15),
      Offset(size.width * 0.90, size.height * 0.15),
      Offset(size.width * 0.10, size.height * 0.85),
      Offset(size.width * 0.90, size.height * 0.85),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: center, width: 13, height: 5), propPaint);
    }

    // spray dots below
    final sprayPaint = Paint()..color = const Color(0x882DD4FF)..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.35 + i * size.width * 0.075, size.height * 0.95 + (i % 2) * 4),
        1.5, sprayPaint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// 4. Drifting animated orbs (replace static _GlowBlobs)
class _DriftingOrbs extends StatelessWidget {
  final AnimationController controller;
  const _DriftingOrbs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value; // 0..1
        return Stack(children: [
          _orb(size, top: -100 + t * 40,  right: -80,        sz: 380, color: AppColors.cyan,   op: 0.18),
          _orb(size, bottom: 60 - t * 30, left: -120,        sz: 340, color: AppColors.orange, op: 0.16),
          _orb(size, top: 320 + t * 60,   right: 20 - t * 20,sz: 280, color: AppColors.green,  op: 0.12),
          _orb(size, bottom: 300 + t * 40,right: -60,        sz: 200, color: AppColors.yellow, op: 0.09),
        ]);
      },
    );
  }

  Widget _orb(Size screen, {double? top, double? bottom, double? left, double? right,
      required double sz, required Color color, required double op}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: IgnorePointer(
        child: Container(
          width: sz, height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: op),
            boxShadow: [BoxShadow(color: color.withValues(alpha: op * 0.8), blurRadius: 80, spreadRadius: 30)],
          ),
        ),
      ),
    );
  }
}

// 5. Floating particle field (tiny glowing dots drifting upward)
class _ParticleField extends StatefulWidget {
  const _ParticleField();
  @override State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(_ctrl.value),
          size: MediaQuery.of(context).size,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  static const _seeds = [
    [0.10, 0.90, 0.0], [0.25, 0.70, 0.3], [0.40, 0.85, 0.6],
    [0.55, 0.60, 0.1], [0.70, 0.80, 0.5], [0.85, 0.65, 0.8],
    [0.15, 0.40, 0.2], [0.60, 0.30, 0.7], [0.90, 0.50, 0.4],
    [0.35, 0.20, 0.9], [0.78, 0.15, 0.15],[0.48, 0.55, 0.55],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _seeds) {
      final phase = (t + s[2]) % 1.0;
      final x = s[0] * size.width;
      final y = size.height * (s[1] - phase * 0.4);
      if (y < 0 || y > size.height) continue;
      final opacity = (math.sin(phase * math.pi) * 0.5).clamp(0.0, 0.5);
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        Paint()
          ..color = AppColors.green.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

// ----------------------------------------------------------
// Reusable scroll-entry wrapper â€” fires once when ~18% visible.
// ----------------------------------------------------------
class _ScrollReveal extends StatefulWidget {
  final Widget child;
  final int index;
  const _ScrollReveal({required this.child, this.index = 0});

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal> with SingleTickerProviderStateMixin {
  bool _triggered = false;
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _curve = CurvedAnimation(parent: _controller, curve: const Cubic(0.16, 1, 0.3, 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_triggered && info.visibleFraction > 0.18) {
      _triggered = true;
      // fire immediately, with a tiny stagger by index
      Future.delayed(Duration(milliseconds: widget.index * 40), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reveal_${widget.hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          final t = _curve.value;
          return Opacity(
            opacity: t,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translate(0.0, 40 * (1 - t))
                ..rotateX(0.14 * (1 - t))
                ..scale(0.96 + (0.04 * t)),
              child: widget.child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ----------------------------------------------------------
// Section heading â€” tag label rendered bold + underlined,
// per your request (e.g. "OUR MISSION", "FEATURES", "ABOUT US").
// ----------------------------------------------------------
class _SectionHead extends StatefulWidget {
  final String tagKey;
  final String titleKey;
  const _SectionHead({required this.tagKey, required this.titleKey});
  @override State<_SectionHead> createState() => _SectionHeadState();
}

class _SectionHeadState extends State<_SectionHead> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _width;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _width = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    // slight delay for natural feel
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(
          lang.t(widget.tagKey),
          style: bodyFont(size: 14, weight: FontWeight.w800, color: AppColors.green)
              .copyWith(letterSpacing: 2.0),
        ),
        const SizedBox(width: 10),
        // animated line extends outward
        AnimatedBuilder(
          animation: _width,
          builder: (_, __) => Container(
            width: _width.value * 40,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.green, AppColors.green.withValues(alpha: 0)]),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Text(lang.t(widget.titleKey), style: headingFont(size: 32)),
    ]);
  }
}

// ----------------------------------------------------------
// Mission card â€” tap to glow. Background opacity raised from
// the original ~7% white to ~15%/8% so the card reads less
// see-through against the busy gradient background.
// ----------------------------------------------------------
class _MissionCard extends StatefulWidget {
  final CustomPainter iconPainter;
  final Color glow;
  final String titleKey;
  final String bodyKey;
  const _MissionCard({required this.iconPainter, required this.glow, required this.titleKey, required this.bodyKey});

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _active = true),
      onTapUp: (_) => setState(() => _active = false),
      onTapCancel: () => setState(() => _active = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _active
                ? [widget.glow.withValues(alpha: 0.18), widget.glow.withValues(alpha: 0.06)]
                : [const Color(0x26FFFFFF), const Color(0x0DFFFFFF)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _active ? widget.glow.withValues(alpha: 0.5) : AppColors.glassBorder,
          ),
          boxShadow: _active
              ? [BoxShadow(color: widget.glow.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 2)]
              : [],
        ),
        transform: Matrix4.translationValues(0, _active ? -6 : 0, 0),
        child: Stack(
          children: [
            // decorative corner accent
            Positioned(
              right: -8, bottom: -8,
              child: CustomPaint(
                size: const Size(80, 60),
                painter: _MissionAccentPainter(widget.glow, _active),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _active ? widget.glow : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _active ? [BoxShadow(color: widget.glow, blurRadius: 24)] : [],
                  ),
                  alignment: Alignment.center,
                  transform: Matrix4.rotationZ(_active ? -0.14 : 0),
                  transformAlignment: Alignment.center,
                  child: CustomPaint(size: const Size(26, 26), painter: widget.iconPainter),
                ),
                const SizedBox(height: 16),
                Text(lang.t(widget.titleKey),
                    style: bodyFont(size: 17, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text(lang.t(widget.bodyKey),
                    style: bodyFont(size: 13, color: AppColors.textBody).copyWith(height: 1.55)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Decorative organic accent shape for mission cards (leaf/root motif)
class _MissionAccentPainter extends CustomPainter {
  final Color color;
  final bool active;
  const _MissionAccentPainter(this.color, this.active);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: active ? 0.18 : 0.06)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, 0)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.1, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.3, size.height * 1.1, size.width, size.height)
      ..close();
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant _MissionAccentPainter o) => o.active != active;
}

// ----------------------------------------------------------
// Custom-drawn mission icons â€” line art, color comes from the
// icon-box state so it flips white<->dark exactly like before.
// ----------------------------------------------------------

/// Sustainability â€” solar panel + sun, for the solar-powered
/// spraying detail in the mission copy.
class _SustainabilityIconPainter extends CustomPainter {
  const _SustainabilityIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;

    final panel = Path()
      ..moveTo(w * 0.08, h * 0.62)
      ..lineTo(w * 0.40, h * 0.40)
      ..lineTo(w * 0.92, h * 0.55)
      ..lineTo(w * 0.62, h * 0.80)
      ..close();
    canvas.drawPath(panel, paint);
    canvas.drawLine(Offset(w * 0.24, h * 0.50), Offset(w * 0.46, h * 0.70), paint);
    canvas.drawLine(Offset(w * 0.40, h * 0.40), Offset(w * 0.62, h * 0.80), paint);
    canvas.drawLine(Offset(w * 0.66, h * 0.47), Offset(w * 0.78, h * 0.74), paint);

    canvas.drawCircle(Offset(w * 0.62, h * 0.18), w * 0.09, paint);
    final rayOffsets = [
      [Offset(w * 0.62, h * 0.02), Offset(w * 0.62, h * 0.08)],
      [Offset(w * 0.50, h * 0.06), Offset(w * 0.55, h * 0.11)],
      [Offset(w * 0.74, h * 0.06), Offset(w * 0.69, h * 0.11)],
      [Offset(w * 0.46, h * 0.18), Offset(w * 0.52, h * 0.18)],
      [Offset(w * 0.78, h * 0.18), Offset(w * 0.72, h * 0.18)],
    ];
    for (final pair in rayOffsets) {
      canvas.drawLine(pair[0], pair[1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Farmer's Health â€” shield with a cross, for protection from
/// pesticide drift and blowback.
class _HealthIconPainter extends CustomPainter {
  const _HealthIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;

    final shield = Path()
      ..moveTo(w * 0.5, h * 0.06)
      ..lineTo(w * 0.86, h * 0.20)
      ..lineTo(w * 0.86, h * 0.52)
      ..cubicTo(w * 0.86, h * 0.78, w * 0.68, h * 0.92, w * 0.5, h * 0.96)
      ..cubicTo(w * 0.32, h * 0.92, w * 0.14, h * 0.78, w * 0.14, h * 0.52)
      ..lineTo(w * 0.14, h * 0.20)
      ..close();
    canvas.drawPath(shield, paint);

    canvas.drawLine(Offset(w * 0.5, h * 0.34), Offset(w * 0.5, h * 0.62), paint);
    canvas.drawLine(Offset(w * 0.37, h * 0.48), Offset(w * 0.63, h * 0.48), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Economics and Agriculture â€” leaf + rupee mark, for cost
/// savings and crop yield together.
class _EconomicsIconPainter extends CustomPainter {
  const _EconomicsIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;

    final leaf = Path()
      ..moveTo(w * 0.10, h * 0.85)
      ..cubicTo(w * 0.05, h * 0.55, w * 0.18, h * 0.30, w * 0.42, h * 0.22)
      ..cubicTo(w * 0.40, h * 0.50, w * 0.30, h * 0.72, w * 0.10, h * 0.85)
      ..close();
    canvas.drawPath(leaf, paint);
    canvas.drawLine(Offset(w * 0.14, h * 0.78), Offset(w * 0.36, h * 0.32), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------
// Feature card â€” glassmorphism with a live preview pane inside.
// Each card shows a mini-preview of its feature (just like the
// weather widget in the reference designs). Tap navigates to
// the full screen.
// ----------------------------------------------------------
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String bodyKey;
  final Widget previewChild;
  final void Function(BuildContext ctx) onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.bodyKey,
    required this.previewChild,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  // Derives a dark-tinted version of the accent for the card face
  Color get _face {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness(0.12).withSaturation(0.45).toColor();
  }

  // Light shadow — slightly lighter than face, same hue
  Color get _shadowLight {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness(0.22).withSaturation(0.35).toColor();
  }

  // Dark shadow — near-black with hue tint
  Color get _shadowDark {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness(0.04).withSaturation(0.40).toColor();
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _face,
          borderRadius: BorderRadius.circular(22),
          border: Border(
            top: BorderSide(color: widget.color.withOpacity(0.75), width: 2.5),
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _shadowDark.withOpacity(0.9),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: _shadowLight.withOpacity(0.30),
                    offset: const Offset(-2, -2),
                    blurRadius: 6,
                  ),
                ]
              : [
                  BoxShadow(
                    color: _shadowDark.withOpacity(0.85),
                    offset: const Offset(6, 6),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: _shadowLight.withOpacity(0.40),
                    offset: const Offset(-5, -5),
                    blurRadius: 14,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    // â”€â”€ Preview pane â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.color.withOpacity(0.55),
                            widget.color.withOpacity(0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: widget.previewChild,
                  ),
                        ],
                      ),
                    ),

                    // â”€â”€ Frosted label strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: _shadowDark.withOpacity(0.60),
                border: Border(
                  top: BorderSide(color: widget.color.withOpacity(0.18)),
                ),
              ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _face,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowDark.withOpacity(0.7),
                            offset: const Offset(2, 2),
                            blurRadius: 4 + _pulseAnim.value * 2,
                          ),
                          BoxShadow(
                            color: _shadowLight.withOpacity(0.25 + _pulseAnim.value * 0.1),
                            offset: const Offset(-2, -2),
                            blurRadius: 4 + _pulseAnim.value * 2,
                          ),
                        ],
                      ),
                              alignment: Alignment.center,
                              child: Icon(widget.icon, size: 16, color: widget.color),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Builder(builder: (ctx) {
                              final lang = LanguageScope.of(ctx);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.t(widget.titleKey),
                                    style: bodyFont(size: 12, weight: FontWeight.w700, color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Text(
                                      "Open",
                                      style: bodyFont(size: 10, color: widget.color),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 9, color: widget.color),
                                  ]),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// FEATURE CARD PREVIEW WIDGETS
// Each one is a compact, non-interactive miniature of what
// the user will see when they open the feature screen.
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// â”€â”€ 1. Map Preview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Field Mapping", style: bodyFont(size: 10, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        // Mini map placeholder
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4A35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Grid lines
                CustomPaint(
                  size: Size.infinite,
                  painter: _MapGridPainter(),
                ),
                // Spray path
                Center(
                  child: CustomPaint(
                    size: const Size(80, 56),
                    painter: _SprayPathPainter(),
                  ),
                ),
                // GPS pin
                const Positioned(
                  bottom: 12,
                  right: 12,
                  child: Icon(Icons.my_location, size: 14, color: AppColors.orange),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Area stat
        Row(children: [
          _miniStat("1.4 ac", AppColors.cyan),
          const SizedBox(width: 8),
          _miniStat("Recorded", AppColors.green),
        ]),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.8;
    const step = 16.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SprayPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withOpacity(0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.2)
      ..lineTo(size.width * 0.95, size.height * 0.2)
      ..lineTo(size.width * 0.95, size.height * 0.5)
      ..lineTo(size.width * 0.05, size.height * 0.5)
      ..lineTo(size.width * 0.05, size.height * 0.8)
      ..lineTo(size.width * 0.95, size.height * 0.8);
    canvas.drawPath(path, paint);

    // dots along path
    final dot = Paint()..color = AppColors.orange..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.8), 3.5, dot);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}


// ── 2. Weather Preview — fetches live temperature ─────────────────────────
class _WeatherPreview extends StatefulWidget {
  const _WeatherPreview();
  @override
  State<_WeatherPreview> createState() => _WeatherPreviewState();
}

class _WeatherPreviewState extends State<_WeatherPreview> {
  String _temp = '—';
  String _icon = '🌤️';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchTemp();
  }

  Future<void> _fetchTemp() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      final data = await WeatherService().getWeather(pos.latitude, pos.longitude);
      final cur = data['current'] as Map<String, dynamic>;
      final tempInt = (cur['temperature_2m'] as num).round();
      final code = (cur['weathercode'] as num?)?.toInt() ?? 0;
      final hour = DateTime.now().hour;
      final isNight = hour < 6 || hour >= 20;
      final icon = _iconFor(code, isNight);
      if (mounted) setState(() { _temp = '$tempInt°'; _icon = icon; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() { _temp = '—'; _loaded = true; });
    }
  }

  String _iconFor(int code, bool isNight) {
    if (code == 0)                return isNight ? '🌙' : '☀️';
    if (code == 1)                return isNight ? '🌙' : '🌤️';
    if (code == 2)                return '⛅';
    if (code == 3)                return '☁️';
    if (code >= 45 && code <= 48) return '🌫️';
    if (code >= 51 && code <= 55) return '🌦️';
    if (code >= 61 && code <= 65) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code >= 95 && code <= 99) return '⛈️';
    return isNight ? '🌙' : '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Weather", style: bodyFont(size: 10, color: AppColors.textMuted)),
            const Icon(Icons.cloud_queue, size: 12, color: AppColors.orange),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _loaded ? _temp : '…',
          style: monoFont(size: 28, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(_icon, style: const TextStyle(fontSize: 22)),
      ],
    );
  }
}
class _ReportPreview extends StatelessWidget {
  const _ReportPreview();

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFD4A843);
    const paperBg = Color(0xFF1A1208); // very dark warm paper tone
    return Container(
      decoration: BoxDecoration(
        color: paperBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: amber.withOpacity(0.25), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header band — like a report title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: amber.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SPRAY SESSION REPORT',
              style: bodyFont(size: 7, weight: FontWeight.w800, color: amber)
                  .copyWith(letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 5),
          // Ruled data lines
          _reportLine('Plot', 'North Plot A', amber),
          _ruleDivider(),
          _reportLine('Area', '1.4 ac', amber),
          _ruleDivider(),
          _reportLine('Coverage', '91.5%', const Color(0xFF7EC87A)),
          _ruleDivider(),
          _reportLine('Sessions', '3 recorded', amber),
          const SizedBox(height: 6),
          // Stamp — sits below the data, right-aligned
          Align(
            alignment: Alignment.centerRight,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF7EC87A).withOpacity(0.7), width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '✓ DONE',
                  style: bodyFont(size: 7, weight: FontWeight.w900,
                      color: const Color(0xFF7EC87A).withOpacity(0.75))
                      .copyWith(letterSpacing: 1.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportLine(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: bodyFont(size: 8, color: const Color(0xFFBBA060))),
          const Spacer(),
          Text(value, style: bodyFont(size: 8, weight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }

  Widget _ruleDivider() => Container(
    height: 0.5,
    color: const Color(0xFFD4A843).withOpacity(0.15),
  );
}
// â”€â”€ Networking feature card preview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _NetworkingPreview extends StatelessWidget {
  const _NetworkingPreview();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 90),
      painter: _FarmerNetworkPainter(),
    );
  }
}

// Organic scattered network — nodes of varying sizes connected in a web,
// inspired by social/farmer network maps. No profile icons, pure connectivity.
class _FarmerNetworkPainter extends CustomPainter {
  const _FarmerNetworkPainter();

  // Node positions as fractions of (width, height), with radius scale
  // [xFrac, yFrac, radiusScale]  1.0 = normal, 1.6 = hub
  static const _nodes = [
    [0.08, 0.22, 1.0],  // 0 — far left top
    [0.22, 0.55, 1.0],  // 1 — left mid
    [0.18, 0.85, 0.8],  // 2 — left bottom
    [0.38, 0.18, 0.8],  // 3 — top centre-left
    [0.42, 0.50, 1.6],  // 4 — main hub (centre)
    [0.38, 0.82, 1.0],  // 5 — centre bottom
    [0.60, 0.28, 1.0],  // 6 — top right
    [0.65, 0.65, 0.8],  // 7 — right mid-low
    [0.80, 0.40, 1.2],  // 8 — right hub
    [0.92, 0.70, 0.8],  // 9 — far right bottom
    [0.75, 0.88, 0.7],  // 10 — right bottom
    [0.55, 0.92, 0.7],  // 11 — bottom centre
  ];

  // Edges — [from, to]
  static const _edges = [
    [0, 1], [0, 3],
    [1, 2], [1, 4], [1, 3],
    [2, 5],
    [3, 4], [3, 6],
    [4, 5], [4, 6], [4, 7], [4, 8],
    [5, 11], [5, 7],
    [6, 8],
    [7, 8], [7, 10], [7, 11],
    [8, 9],
    [9, 10],
    [10, 11],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const baseColor  = Color(0xFF6B8FE8); // ultramarine node blue
    const lineColor  = Color(0xFF3A5FCD);
    const hubColor   = Color(0xFF8FAAFF); // brighter for main hub

    // Draw edges first (behind nodes)
    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (final e in _edges) {
      final a = Offset(_nodes[e[0]][0] * w, _nodes[e[0]][1] * h);
      final b = Offset(_nodes[e[1]][0] * w, _nodes[e[1]][1] * h);
      // lines fade based on distance — closer = more opaque
      final dist = (b - a).distance;
      final opacity = (1.0 - (dist / w) * 0.8).clamp(0.18, 0.55);
      linePaint.color = lineColor.withOpacity(opacity);
      canvas.drawLine(a, b, linePaint);
    }

    // Draw nodes on top
    for (int i = 0; i < _nodes.length; i++) {
      final nx = _nodes[i][0] * w;
      final ny = _nodes[i][1] * h;
      final rs = _nodes[i][2];
      final pos = Offset(nx, ny);
      final isHub = rs >= 1.5;
      final baseR = isHub ? 6.5 : 4.0 * rs;
      final color = isHub ? hubColor : baseColor;

      // outer glow
      canvas.drawCircle(pos, baseR + 4,
          Paint()
            ..color = color.withOpacity(0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

      // ring
      canvas.drawCircle(pos, baseR + 1.5,
          Paint()
            ..color = color.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);

      // filled core
      canvas.drawCircle(pos, baseR,
          Paint()
            ..color = isHub
                ? color.withOpacity(0.90)
                : color.withOpacity(0.55)
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}



Widget _miniStat(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label, style: bodyFont(size: 9, color: color)),
  );
}

// ----------------------------------------------------------
// About box â€” content fully replaced with PreciSpray copy.
// Background opacity raised the same way as the other cards.
// ----------------------------------------------------------
class _AboutBox extends StatefulWidget {
  const _AboutBox();
  @override State<_AboutBox> createState() => _AboutBoxState();
}

class _AboutBoxState extends State<_AboutBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Night field illustrated background
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _NightFieldPainter(_ctrl.value),
            ),
          ),
          // glassmorphism overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x80061B12), Color(0xCC04120D)],
                ),
                border: Border.all(color: AppColors.glassBorder),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.eco_outlined, size: 18, color: AppColors.cyan),
                ),
                const SizedBox(width: 10),
                Text("Who we are", style: bodyFont(size: 12, color: AppColors.cyan, weight: FontWeight.w700)
                    .copyWith(letterSpacing: 1.0)),
              ]),
              const SizedBox(height: 14),
              Text(
                lang.t('about_body'),
                style: bodyFont(size: 14, color: AppColors.textBody).copyWith(height: 1.7),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// Night field painter â€” inspired by image 4 (Farmvest night scene)
class _NightFieldPainter extends CustomPainter {
  final double t; // 0..1 breathing animation
  _NightFieldPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF03100A), Color(0xFF061B12)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // stars (twinkling via t)
    final starPositions = [
      [0.1, 0.15], [0.25, 0.08], [0.42, 0.20], [0.58, 0.06],
      [0.72, 0.18], [0.88, 0.10], [0.33, 0.30], [0.65, 0.25],
      [0.80, 0.32], [0.15, 0.35], [0.50, 0.12], [0.93, 0.28],
    ];
    for (int i = 0; i < starPositions.length; i++) {
      final phase = (t + i * 0.083) % 1.0;
      final op = 0.3 + math.sin(phase * math.pi) * 0.4;
      canvas.drawCircle(
        Offset(starPositions[i][0] * size.width, starPositions[i][1] * size.height),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: op),
      );
    }

    // distant wind turbines (static silhouettes)
    _drawTurbine(canvas, size, 0.20, 0.55, t);
    _drawTurbine(canvas, size, 0.55, 0.48, t * 0.7);
    _drawTurbine(canvas, size, 0.80, 0.58, t * 1.3 % 1.0);

    // rolling field layers
    final f1 = Paint()..color = const Color(0x660A2D1F);
    final f1Path = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.55, size.width * 0.6, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.58, size.width, size.height * 0.63)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(f1Path, f1);

    final f2 = Paint()..color = const Color(0x880C3220);
    final f2Path = Path()
      ..moveTo(0, size.height * 0.80)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.72, size.width * 0.7, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.74, size.width, size.height * 0.79)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(f2Path, f2);
  }

  void _drawTurbine(Canvas canvas, Size size, double xFrac, double yFrac, double phase) {
    final cx = xFrac * size.width;
    final cy = yFrac * size.height;
    final p = Paint()..color = const Color(0x994ADE80)..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    // tower
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy + size.height * 0.22), p);

    // 3 blades rotating
    final bladeLen = size.height * 0.09;
    for (int i = 0; i < 3; i++) {
      final angle = phase * 2 * math.pi + (i * 2 * math.pi / 3);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + bladeLen * math.cos(angle), cy + bladeLen * math.sin(angle)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NightFieldPainter old) => old.t != t;
}
