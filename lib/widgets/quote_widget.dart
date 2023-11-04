import 'package:flutter/material.dart';

class QuoteWidget extends StatelessWidget {
  const QuoteWidget({
    required this.quote,
    required this.quoteBy,
    required this.fontsize,
    Key? key,
  }) : super(key: key);
  final String quote;
  final String quoteBy;
  final double fontsize;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              quote,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontsize,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              quoteBy,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontsize - 2,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
