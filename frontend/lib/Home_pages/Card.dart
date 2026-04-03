import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class CardOrdres extends StatelessWidget {
     CardOrdres({super.key, required this.path});
  final String path ;
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: [
        Card(
          child: Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Opacity(
                            opacity: .4,
                            child: Text(
                              "Plumbing",
                              style: GoogleFonts.instrumentSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                            
                              ),
                            ),
                          ),
                          Text(
                            "Leaky faucet repair",
                            style: GoogleFonts.instrumentSans(fontSize: 18,
                              fontWeight: FontWeight.bold,),
                          ),
                          Opacity(
                            opacity: .4,
                            child: Text(
                              "John doe,2.5 miles away",
                              style: GoogleFonts.instrumentSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Image.asset(path, height: 80, width: 80),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 129,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1EBBF0),
                          ),
                          child: Text(
                            "Accept",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 129,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                          ),
                          child: Text(
                            "Decline",
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
