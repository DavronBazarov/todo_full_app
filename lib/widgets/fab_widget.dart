import 'package:flutter/material.dart';
import 'package:todo_full_app/widgets/simple_dialog_widget.dart';

class FABWidget extends StatelessWidget {
  const FABWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration:const BoxDecoration(
        color:Colors.teal,
        shape: BoxShape.circle,
      ),
      child: IconButton(

        splashColor: Colors.pinkAccent,

        tooltip: 'Add a new task',
        onPressed: () async {
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) {
              return Dia(ctx: ctx, index: 0);
            },
          );
        },
        icon: const Icon(
          Icons.add,
          size: 34,
          color: Colors.white,
        ),
      ),
    );
  }
}
