---
title: Overview
sidebar_position: 1
---

# Overview for `TableButton`

## Description

[TableButton] is an outlined button designed to accompany [Table] widgets.

 This button is styled to have rounded bottom corners when placed below a [Table] or rounded top corners when
 displayed above a [Table]. This allows to button to appear as an extension of the [Table], especially when the
 [Table] also adapts its border styling to mirror that of this button.

## Dependencies

- StatelessWidget

## Members

- **onTap**: `VoidCallback`
  A callback invoked when the button is tapped.

- **side**: `ButtonSide`
  Determines the side of the [Table] or other widget on which the [TableButton] will appear. This parameter can
 accept values of [ButtonSide.top] or [ButtonSide.bottom]. If set to [ButtonSide.top], the [TableButton] will
 use rounded top corners and square bottom corners. If set to [ButtonSide.bottom], the [TableButton] will
 use rounded bottom corners and square top corners.

- **text**: `String`
  The text label to display on the [TableButton] if [loading] is false.

- **loading**: `bool?`
  Determines whether the button should be displayed in a loading state. If true, the content of the button is
 a [LoadingIndicator]. If false, the content of the button is the [text]. If a value is not provided, the
 [TableButton] will use a value of false by default, meaning the [text] will be displayed on the button.

## Constructors

### Unnamed Constructor
Creates an instance of [TableButton].

