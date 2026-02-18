import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../providers/admin_provider.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    // Pre-fetch stats to show in the Trust Bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildModernHero(context, isDesktop),
            _buildTrustBar(context),
            _buildProcessSection(isDesktop),
            _buildFeaturesGrid(isDesktop),
            _buildBusinessBanner(isDesktop),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // --- 1. HERO SECTION (Layered & Glassmorphic) ---
  Widget _buildModernHero(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      height: isDesktop ? 600 : 500,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
      ),
      child: Stack(
        children: [
          // Background Aesthetic (Water Pattern)
          Positioned(
            right: -100,
            top: -50,
            child: Icon(Icons.water_drop, size: 400, color: Colors.white.withOpacity(0.05)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Logo Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 60, color: AppColors.accentCyan),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "کارواش پرو",
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "تجربه درخشش خودرو، بدون دردسر ترافیک",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 48),
                  
                  // Primary Actions
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      CustomButton(
                        text: "ورود به حساب",
                        width: 200,
                        color: Colors.white,
                        textColor: AppColors.primary,
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                      ),
                      CustomButton(
                        text: "ثبت‌نام مشتری",
                        width: 200,
                        isGlass: true,
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // --- 2. TRUST BAR (Fixed Layout) ---
  Widget _buildTrustBar(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        // Fallback data if provider is empty
        final stats = provider.adminStats ?? {
          "total_users": 15, 
          "active_carwashes": 14, 
          "completed_orders": 9
        };
        
        return Container(
          transform: Matrix4.translationValues(0, -50, 0), // Slightly deeper lift
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), 
                blurRadius: 30, 
                offset: const Offset(0, 15)
              )
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row( // Using Row instead of Wrap for perfect horizontal alignment
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildStatItem("${stats['total_users']}+", "کاربر فعال")),
                // Vertical divider for better visual separation
                Container(width: 1, height: 40, color: Colors.grey[200]), 
                Expanded(child: _buildStatItem("${stats['active_carwashes']}", "کارواش‌\u200cهای معتبر")),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                Expanded(child: _buildStatItem("${stats['completed_orders']}", "سفارش‌\u200cهای موفق")),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Prevents taking unnecessary vertical space
      children: [
        Text(
          val, 
          style: const TextStyle(
            fontSize: 34, // Slightly larger for emphasis
            fontWeight: FontWeight.w900, 
            color: AppColors.primary,
            height: 1.1, // Tightens the line height
          )
        ),
        const SizedBox(height: 8),
        Text(
          label, 
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600], 
            fontSize: 14,
            fontWeight: FontWeight.w600,
          )
        ),
      ],
    );
  }

  // --- 3. PROCESS SECTION (How it works) ---
  Widget _buildProcessSection(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text("چگونه کار می\u200cکنیم؟", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStep(Icons.search, "جستجو", "انتخاب نزدیک\u200cترین کارواش"),
              _buildConnector(isDesktop),
              _buildStep(Icons.event_available, "رزرو", "تعیین زمان دلخواه شما"),
              _buildConnector(isDesktop),
              _buildStep(Icons.sentiment_very_satisfied, "درخشش", "تحویل خودروی پاکیزه"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, String title, String desc) {
    return Column(
      children: [
        CircleAvatar(radius: 35, backgroundColor: AppColors.primaryLight, child: Icon(icon, color: AppColors.primary)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildConnector(bool isHorizontal) {
    return isHorizontal 
      ? Container(width: 80, height: 2, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 20))
      : Container(width: 2, height: 40, color: Colors.grey[200], margin: const EdgeInsets.symmetric(vertical: 10));
  }

  // --- 4. FEATURES GRID ---
  Widget _buildFeaturesGrid(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Colors.white,
      child: Wrap(
        spacing: 30,
        runSpacing: 30,
        alignment: WrapAlignment.center,
        children: [
          _buildFeatureCard(icon: Icons.timer, title: "صرفه\u200cجویی در زمان", desc: "دیگر نیازی به ماندن در ترافیک نیست. ما به محل شما می\u200cآییم.", color: Colors.orange),
          _buildFeatureCard(icon: Icons.verified_user, title: "متخصصین حرفه\u200cای", desc: "تمام پرسنل ما احراز هویت شده و آموزش دیده هستند.", color: Colors.green),
          _buildFeatureCard(icon: Icons.price_check, title: "قیمت شفاف", desc: "هزینه خدمات از قبل مشخص است. بدون انعام اجباری.", color: Colors.purple),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String desc, required Color color}) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.6)),
        ],
      ),
    );
  }

  // --- 5. BUSINESS CTA ---
  Widget _buildBusinessBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      color: AppColors.secondary,
      child: Column(
        children: [
          const Text("صاحب کارواش هستید؟", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("کسب و کار خود را آنلاین کنید و مشتریان جدید جذب کنید.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 40),
          CustomButton(
            text: "ثبت درخواست همکاری",
            color: Colors.white,
            textColor: AppColors.secondary,
            width: 250,
            onPressed: () => Navigator.pushNamed(context, '/apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Text("© 2026 Carwash Pro Team - All Rights Reserved", style: TextStyle(color: Colors.grey)),
    );
  }
}