import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/clean_minimal_tooltip_widget.dart';

// Focus widget keys for this walkthrough
final container1u3esfep = GlobalKey();

/// workoutFirst
///
///
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// Step 1
      TargetFocus(
        keyTarget: container1u3esfep,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => CleanMinimalTooltipWidget(
              stepText: '1 of 3',
              title: 'Log as you go',
              body:
                  'Each row is one set — enter your reps and weight, then tap the check on the right to complete it.',
            ),
          ),
        ],
      ),

      /// Step 2
      TargetFocus(
        keyTarget: container1u3esfep,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => CleanMinimalTooltipWidget(
              stepText: '2 of 3',
              title: 'AI form check',
              body:
                  'On supported exercises you\'ll see a camera icon — tap it to record a set and get instant technique feedback.',
            ),
          ),
        ],
      ),

      /// Step 3
      TargetFocus(
        keyTarget: container1u3esfep,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => CleanMinimalTooltipWidget(
              stepText: '3 of 3',
              title: 'Rest between sets',
              body:
                  'Set a rest time at the top of the exercise and a timer will run for you after each completed set.',
            ),
          ),
        ],
      ),
    ];
