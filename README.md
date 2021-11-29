# ScrollEdgeControl

Replacement of UIRefreshControl, and more functions.

## Overview

ScrollEdgeControl is a UI component that is similar to UIRefreshControl. but it pulls up to the even further abstracted component.

ScrollEdgeControl can attach to every edge in a scroll view. 
For instance, pulling to down, up, left, right to trigger something activity such as refreshing. (pull-to-activate)

It supports also disabling pull-to-activate, it would be useful in case of displaying as a loading indicator at bottom of the list.

## Showcase

**Vertical**
| Top | Bottom |
|---|---|
| <img width=250px src="https://user-images.githubusercontent.com/1888355/143772795-e35f0b9f-b7b1-4c9e-90ee-fabbdb62d0cd.gif" /> | <img width=250px src="https://user-images.githubusercontent.com/1888355/143772658-0cfa987a-e61e-404b-a5b0-ed296d534817.gif" /> | 

**Horizontal**
| Left | Bottom |
|---|---|
| <img width=250px src="https://user-images.githubusercontent.com/1888355/143772891-6a8431a7-bb50-467d-934e-02b8d8e8d7e3.gif" /> | <img width=250px src="https://user-images.githubusercontent.com/1888355/143772913-1d1b958e-9347-4664-a596-5990817c566c.gif" /> | 

**More patterns**
| pull to refresh and additional loadings |
|---|
| <img width=250px src="https://user-images.githubusercontent.com/1888355/143773010-229a1934-c318-4005-a49a-9fc0f1b96a42.gif" /> |

## Installation

**Cocoapods**

Including custom activity indicator
```ruby
pod "ScrollEdgeControl"
```

If you need only core component
```ruby
pod "ScrollEdgeControl/Core"
```

**SwiftPM**

```swift
dependencies: [
    .package(url: "https://github.com/muukii/ScrollEdgeControl.git", exact: "<VERSION>")
]
```

## How to use

**Setting up**

```swift
let scrollEdgeControl = ScrollEdgeControl(
  edge: .top, // ✅ a target edge to add this control
  configuration: .init(),  // ✅ customizing behavior of this control
  activityIndicatorView: ScrollEdgeActivityIndicatorView(color: .black) // ✅ Adding your own component to display on this control
)
```

```swift
let scrollableView: UIScrollView // ✅ could be `UIScrollView`, `UITableView`, `UICollectionView`

scrollableView.addSubview(scrollEdgeControl) // ✅ Could add multiple controls for each edge
```

**Handling**

```swift
scrollEdgeControl.handlers.onDidActivate = { instance in

  ...

  // after activity completed
  instance.setActivityState(.inactive, animated: true)
}
```

## Behind the scenes

WIP

## Why uses Advance in dependency

Advance helps animation in the scroll view.

It is a library to run animations with fully computable values using CADisplayLink.

UIScrollView's animations are not in CoreAnimation.  
Those are computed in CPU every frame. that's why we can handle it in the UIScrollView delegate.  
We can update content offset with UIView animation, but sometimes it's going to be weird animation.  
To solve it, using CADisplayLink, update values for each frame.

Refs:  
- https://medium.com/@esskeetit/how-uiscrollview-works-e418adc47060#97c7

## Author

- [Muukii](https://github.com/muukii)
- [takumatt](https://github.com/takumatt)

## License

MIT
