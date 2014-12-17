//
//  SwipePageViewController.swift
//  SwipePageViewController
//
//  Created by Francisco Javier Horrillo Sancho on 17/12/14.
//  Copyright (c) 2014 Francisco Javier Horrillo Sancho. All rights reserved.
//

import UIKit

// customizeable button attributes
let X_BUFFER: CGFloat = 0  // the number of pixels on either side of the segment
let Y_BUFFER: CGFloat = 0  // number of pixels on top of the segment
let HEIGHT: CGFloat   = 45 // height of the segment

// customizeable selector bar attributes (the black bar under the buttons)
let ANIMATION_SPEED   = 0.2         // the number of seconds it takes to complete the animation
let SELECTOR_Y_BUFFER: CGFloat = 40 // the y-value of the bar that shows what page you are on (0 is the top)
let SELECTOR_HEIGHT: CGFloat   = 4  // thickness of the selector bar

let X_OFFSET: CGFloat = 8 // for some reason there's a little bit of a glitchy offset.  I'm going to look for a better workaround in the future

protocol SwipePageViewControllerDelegate {
    
}

@IBDesignable class SwipePageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate {
    // Public attributes
    var pageScrollView: UIScrollView?
    var currentPageIndex: NSInteger! = 0
    // Delegate class
    private var navDelegate: SwipePageViewControllerDelegate?
    // Private attributes
    @IBInspectable var pageStoryboardIDs: String?
    var pages: [UIViewController]! = [UIViewController()]
    private var navigationView: UIView?
    private var selectionBar: UIView?
    
    // MARK: - Customizable
    // NOTE: This stuff here is customizeable: buttons, views, etc
    
    // sets up the tabs using a loop.  You can take apart the loop to customize individual buttons, but remember to tag the buttons.  (button.tag=0 and the second button.tag=1, etc)
    func setupSegmentButtons() {
        navigationView = UIView(frame: CGRectMake(0, 0, self.navigationController!.view.frame.size.width, self.navigationController!.navigationBar.frame.size.height))
        
        let numControllers = pages.count
        
        for (var i = 0; i < numControllers; i++) {
            var button: UIButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
            button.frame = CGRectMake(X_BUFFER + CGFloat(i) * (self.navigationController!.view.frame.size.width - 2 * X_BUFFER) / CGFloat(numControllers) - X_OFFSET, Y_BUFFER, (self.navigationController!.view.frame.size.width - 2 * X_BUFFER) / CGFloat(numControllers), HEIGHT)
            navigationView!.addSubview(button)
            
            button.tag = i // IMPORTANT: if you make your own custom buttons, you have to tag them appropriately
            button.addTarget(self, action: Selector("tapSegmentButtonAction:"), forControlEvents: UIControlEvents.TouchUpInside)
            button.setTitle(pages[i].title, forState: UIControlState.Normal) //buttontitle
        }
        
        self.navigationController!.navigationBar.topItem?.titleView = navigationView
        
        // example custom buttons example:
        /*
        NSInteger width = (self.navigationController!.view.frame.size.width-(2*X_BUFFER))/3;
        UIButton *leftButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER, Y_BUFFER, width, HEIGHT)];
        UIButton *middleButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+width, Y_BUFFER, width, HEIGHT)];
        UIButton *rightButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+2*width, Y_BUFFER, width, HEIGHT)];
        
        [self.navigationController!.navigationBar addSubview:leftButton];
        [self.navigationController!.navigationBar addSubview:middleButton];
        [self.navigationController!.navigationBar addSubview:rightButton];
        
        leftButton.tag = 0;
        middleButton.tag = 1;
        rightButton.tag = 2;
        
        leftButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
        middleButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
        rightButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
        
        [leftButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [middleButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [rightButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [leftButton setTitle:@"left" forState:UIControlStateNormal];
        [middleButton setTitle:@"middle" forState:UIControlStateNormal];
        [rightButton setTitle:@"right" forState:UIControlStateNormal];
        */
        
        if (pageScrollView != nil) {
            self.setupSelector()
        }
    }
    
    // sets up the selection bar under the buttons on the navigation bar
    func setupSelector() {
        selectionBar = UIView(frame: CGRectMake(X_BUFFER-X_OFFSET, SELECTOR_Y_BUFFER, (self.navigationController!.view.frame.size.width - 2 * X_BUFFER) / CGFloat(pages.count), SELECTOR_HEIGHT))
        selectionBar!.backgroundColor = UIColor(red: 0, green: 0.48, blue: 1, alpha: 1) // sbcolor
        selectionBar!.alpha = 1 // sbalpha
        navigationView!.addSubview(selectionBar!)
    }

    // MARK: - Setup
    // NOTE: generally, this shouldn't be changed unless you know what you're changing
    
    override func viewWillAppear(animated: Bool) {
        self.setupPageViewController()
        if (self.navigationController != nil) {
            self.setupSegmentButtons()
        }
    }
    
    // generic setup stuff for a pageview controller.  Sets up the scrolling style and delegate for the controller
    func setupPageViewController() {
        self.delegate = self
        self.dataSource = self
        
        if (self.pageStoryboardIDs != nil) {
            pages = []
            for id in self.pageStoryboardIDs!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ",; ")) {
                let viewController: UIViewController = self.storyboard?.instantiateViewControllerWithIdentifier(id) as UIViewController
                pages.append(viewController)
            }
        }
        
        self.setViewControllers([pages[currentPageIndex]], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        self.syncScrollView()
    }
    
    // this allows us to get information back from the scrollview, namely the coordinate information that we can link to the selection bar.
    func syncScrollView() {
        for view in self.view.subviews {
            if(view.isKindOfClass(UIScrollView)) {
                pageScrollView = (view as UIScrollView)
                pageScrollView!.delegate = self
            }
        }
        println()
    }
    
    // MARK: - Implement movement
    // NOTE: methods called when you tap a button or scroll through the pages generally shouldn't touch this unless you know what you're doing or have a particular performance thing in mind
    
    // when you tap one of the buttons, it shows that page, but it also has to animate the other pages to make it feel like you're crossing a 2d expansion, so there's a loop that shows every view controller in the array up to the one you selected
    // eg: if you're on page 1 and you click tab 3, then it shows you page 2 and then page 3
    func tapSegmentButtonAction(button: UIButton) {
        let tempIndex = currentPageIndex
        
        weak var weakSelf = self
        
        // check to see if you're going left -> right or right -> left
        if (button.tag > tempIndex) {
            // scroll through all the objects between the two points
            for (var i = tempIndex+1; i<=button.tag; i++) {
                self.setViewControllers([pages[i]], direction:UIPageViewControllerNavigationDirection.Forward, animated:true, completion: { [weak i = i as AnyObject] (complete: Bool) in
                    // if the action finishes scrolling (i.e. the user doesn't stop it in the middle), then it updates the page that it's currently on
                    if (complete) {
                        weakSelf!.updateCurrentPageIndex(i as NSInteger)
                    }
                })
            }
        }
            
        // this is the same thing but for going right -> left
        else if (button.tag < tempIndex) {
            for (var i = tempIndex-1; i >= button.tag; i--) {
                self.setViewControllers([pages[i]], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: { [weak i = i as AnyObject] (complete: Bool) in
                    if (complete) {
                        weakSelf!.updateCurrentPageIndex(i as NSInteger)
                    }
                })
            }
        }
    }
    
    // makes sure the nav bar is always aware of what page you're on in reference to the array of view controllers you gave
    func updateCurrentPageIndex(newIndex: NSInteger) {
        currentPageIndex = newIndex
    }
    
    // method is called when any of the pages moves.
    // It extracts the xcoordinate from the center point and instructs the selection bar to move accordingly
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (self.navigationController != nil && selectionBar != nil) {
            let xFromCenter = self.navigationController!.view.frame.size.width-pageScrollView!.contentOffset.x // positive for right swipe, negative for left
            
            // checks to see what page you are on and adjusts the xCoor accordingly.
            // i.e. if you're on the second page, it makes sure that the bar starts from the frame.origin.x of the
            // second tab instead of the beginning
            let xCoor = X_BUFFER+selectionBar!.frame.size.width*CGFloat(currentPageIndex)-X_OFFSET
            
            selectionBar!.frame = CGRectMake(xCoor-xFromCenter/CGFloat(pages.count), selectionBar!.frame.origin.y, selectionBar!.frame.size.width, selectionBar!.frame.size.height)
        }
    }
    
    // MARK: - Page View Controller Data Source
    // the delegate functions for UIPageViewController. Pretty standard, but generally, don't touch this.
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = find(pages, viewController)!
        if ((index == NSNotFound) || (index == 0)) {
            return nil
        }
        return pages[--index]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = find(pages, viewController)!
        if (index == NSNotFound || index == pages.count - 1) {
            return nil
        }
        return pages[++index]
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        if (completed) {
            currentPageIndex = find(pages, pageViewController.viewControllers.last as UIViewController)!
        }
    }

}

