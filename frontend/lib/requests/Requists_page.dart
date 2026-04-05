import 'package:flutter/material.dart';
import 'package:frontend/dummy_data/dummy_data.dart';
import 'package:frontend/requests/Widgets/Card_requist.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage>
    with SingleTickerProviderStateMixin {
  bool isActive = true;
  bool isCompleted = false;
  bool isCanceled = false;
  List<RequestCard> selectedcards = cards
      .where((ele) => ele.status != "Accepted" && ele.status != "Canceled")
      .toList();

  // Animation
  late AnimationController _animController;
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buildAnimations();
    _animController.forward();
  }

  void _buildAnimations() {
    _slideAnimations.clear();
    _fadeAnimations.clear();

    final count = selectedcards.length;
    for (int i = 0; i < count; i++) {
      // Each card starts 80ms after the previous one
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.45).clamp(0.0, 1.0);

      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.25), // slides up from below
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  void _triggerAnimation() {
    _buildAnimations();
    _animController.reset();
    _animController.forward();
  }

  void select_tab(String text) {
    if (text == "Active") {
      setState(() {
        selectedcards = cards
            .where(
              (ele) => ele.status != "Accepted" && ele.status != "Canceled",
            )
            .toList();
        isActive = true;
        isCanceled = false;
        isCompleted = false;
      });
    } else if (text == "Completed") {
      setState(() {
        selectedcards =
            cards.where((ele) => ele.status == "Accepted").toList();
        isCompleted = true;
        isCanceled = false;
        isActive = false;
      });
    } else if (text == "Canceled") {
      setState(() {
        selectedcards =
            cards.where((ele) => ele.status == "Canceled").toList();
        isCanceled = true;
        isActive = false;
        isCompleted = false;
      });
    }
    _triggerAnimation();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text(
          "My Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        centerTitle: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tab("Active", isActive),
                const SizedBox(width: 10),
                _tab("Completed", isCompleted),
                const SizedBox(width: 10),
                _tab("Canceled", isCanceled),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return ListView.builder(
                    itemCount: selectedcards.length,
                    itemBuilder: (context, index) {
                      // Safety check in case animations aren't built yet
                      if (index >= _slideAnimations.length) {
                        return selectedcards[index];
                      }
                      return FadeTransition(
                        opacity: _fadeAnimations[index],
                        child: SlideTransition(
                          position: _slideAnimations[index],
                          child: selectedcards[index],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String text, bool isActive) {
    return InkWell(
      onTap: () {
        select_tab(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}