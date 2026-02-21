---
name: StreamerDiag Feedback
about: Describe this issue tFeedback form for StreamerDiag testers. Use this to report
  issues, unexpected behavior, or general feedback.emplate's purpose here.
title: "[StreamerDiag]:"
labels: ''
assignees: DaRatio

---

name: StreamerDiag Feedback
description: Feedback form for StreamerDiag testers
title: "[StreamerDiag]: "
labels: ["StreamerDiag"]
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        Thanks for testing StreamerDiag. Describe anything that looked off or didn’t behave as expected.

  - type: input
    id: device
    attributes:
      label: Device model
      placeholder: "Pixel 7, Samsung S22, etc."
    validations:
      required: true

  - type: input
    id: android_version
    attributes:
      label: Android version
      placeholder: "Android 13"
    validations:
      required: true

  - type: textarea
    id: description
    attributes:
      label: What happened?
      placeholder: "Describe what you saw and what you expected."
    validations:
      required: true

  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      placeholder: "1. Open the app\n2. Tap X\n3. Observe Y"
    validations:
      required: false

  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - Low
        - Medium
        - High
    validations:
      required: true
