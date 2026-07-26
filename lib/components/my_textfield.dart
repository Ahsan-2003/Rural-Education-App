import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  String hintText;
  String labelText;
  final TextEditingController _controller = TextEditingController();

  MyTextfield({super.key, required this.hintText, required this.labelText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          fillColor: Colors.grey.shade100,
          filled: true,
          hintText: hintText,
          label: Text(labelText),
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
    );
  }
}
