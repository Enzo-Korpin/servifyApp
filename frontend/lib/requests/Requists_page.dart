import 'package:flutter/material.dart';
import 'package:frontend/dummy_data/dummy_data.dart';
import 'package:frontend/requests/Widgets/Card_requist.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  bool isActive = true;
  bool isCompleted = false;
  bool isCanceled = false;
  List<RequestCard> selectedcards = cards
      .where((ele) => ele.status != "Accepted" && ele.status != "Canceled")
      .toList();

  void select_tab(String text) {
    if (text == "Active") {
      setState(() {
        selectedcards = cards
            .where(
              (ele) => ele.status != "Accepted" && ele.status != "Canceled",
            )
            .toList();
        isActive = !isActive;
        isCanceled = false;
        isCompleted = false;
      });
    }
    if (text == "Completed") {
      setState(() {
        selectedcards = cards.where((ele) => ele.status == "Accepted").toList();
        isCompleted = !isCompleted;
        isCanceled = false;
        isActive = false;
      });
    }
    if (text == "Canceled") {
      setState(() {
        selectedcards = cards.where((ele) => ele.status == "Canceled").toList();
        isCanceled = !isCanceled;
        isActive = false;
        isCompleted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
            Expanded(child: ListView(children: [...selectedcards])),
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
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
