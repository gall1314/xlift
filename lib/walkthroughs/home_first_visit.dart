import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '/components/clean_minimal_tooltip_widget.dart';

// Focus widget keys for this walkthrough
final buttonFvembopo = GlobalKey();
final containerKt795a1p = GlobalKey();

/// homeFirstVisit
///
/// First-time user walkthrough — guides to first workout
List<TargetFocus> createWalkthroughTargets(BuildContext context) => [
      /// step1: step number 1
      TargetFocus(
        keyTarget: buttonFvembopo,
        enableOverlayTab: true,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, __) => CleanMinimalTooltipWidget(
              stepText: '1 of 2',
              title: 'Start here',
              body:
                  'Create a workout — build it yourself, or let AI plan it for you.',
            ),
          ),
        ],
      ),

      /// step2
      TargetFocus(
        keyTarget: containerKt795a1p,
        enableOverlayTab: true,
        alignSkip: Alignment.topCenter,
        shape: ShapeLightFocus.RRect,
        color: Colors.black,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, __) => CleanMinimalTooltipWidget(
              stepText: '2 of 2',
              title: 'Your AI form coach',
              body:
                  'Tap the sparkle button to record a set from any screen and get instant feedback on your form.',
            ),
          ),
        ],
      ),
    ];
