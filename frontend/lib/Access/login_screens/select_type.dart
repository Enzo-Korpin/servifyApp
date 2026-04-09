import 'package:flutter/material.dart';
import 'package:frontend/Access/login_screens/Login_screen.dart';
import 'package:frontend/Access/signup_screens/Signup_user.dart';
import 'package:frontend/Access/signup_screens/Signup_worker.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectType extends StatelessWidget {
  const SelectType({super.key});



  @override
  Widget build(BuildContext context) {
    
    return  Scaffold(
      body: Padding(
            padding: const EdgeInsets.only(left: 20,right: 20,top:1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80), // 👈 نزّل كل المحتوى لتحت
      
                Center(
                  child: Image.asset(
                    "assets/loghummer.png",
                    width: 110,
                    height: 110,
                  ),
                ),
      
                const SizedBox(height: 3),
      
                Center(
                  child: Text(
                    "Servify",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 55,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "Find help,fast",
                    style: GoogleFonts.inter(
                      color: Color(0xFF6B7280).withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
      
                const SizedBox(height: 5),
      
                Center(
                  child: Image.asset("assets/logo.png", width: 284, height: 269),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 1, left: 20, bottom: 7),
                  child: Text(
                    "Choose You:",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (){
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx)=> StartUser()));
                  },//must go login_worker
                  icon: Icon(Icons.handyman_outlined, size: 24),
                  label: Text(
                    "Provide service",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold,fontSize: 24),
                  ),
                  style: ElevatedButton.styleFrom(alignment: Alignment.centerLeft,
                    backgroundColor: Color.fromARGB(255, 65, 201, 242),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                SizedBox(height: 9),
                ElevatedButton.icon(
                  onPressed: (){
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx)=>SignupUser()));
                  },
                  icon: const Icon(Icons.person, color: Colors.black, size: 24),
                  label: Text(
                    "Need service",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold,fontSize: 24, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(alignment: Alignment.centerLeft,
                    backgroundColor: const Color(0xFFC9C9C9),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    "Have an account?",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      color: Color(0xFF7A8A92),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: (){
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen(),));
                    },
                    child: Text(
                      "Login",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 65, 201, 242),fontSize: 18
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
