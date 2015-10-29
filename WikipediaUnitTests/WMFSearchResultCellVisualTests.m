//
//  WMFSearchResultCellVisualTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBSnapshotTestCase+WMFConvenience.h"
#import "WMFSearchResultCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UIView+VisualTestSizingUtils.h"
#import "MWKTitle.h"

static NSString* const ShortSearchResultTitle = @"One line title";

static NSString* const MediumSearchResultTitle = @"This is a moderately long title that should take up two lines.";

static NSString* const LongSearchResultTitle =
    @"This is an excessively lengthy title that I wrote for testing, which should take up three lines of text"
    " (at the very least).";

static NSString* const ShortSearchResultDescription = @"One line description";

static NSString* const LongSearchResultDescription =
    @"This description describes a search result, and should take approximately three lines to display.";

@interface WMFSearchResultCellVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) WMFSearchResultCell* searchResultCell;
@end

@implementation WMFSearchResultCellVisualTests

- (void)setUp {
    [super setUp];
    //self.recordMode = YES;
    self.searchResultCell = [WMFSearchResultCell wmf_viewFromClassNib];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testShouldShowTitleAtTheTopAndDescriptionAtTheBottom {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldCenterShortTitleWhenDescriptionIsEmpty {
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:nil];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldTruncateAndShrinkTitle {
    NSString* reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldNotShowLongDescriptionWhenTitleExceedsTwoLines {
    NSString* reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:reallyLongString
                           searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:reallyLongString];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldShowLongDescriptionWhenTitleIsShort {
    NSString* reallyLongString = [LongSearchResultTitle stringByAppendingString:LongSearchResultTitle];
    [self populateTitleLabelWithString:ShortSearchResultTitle searchQuery:nil];
    [self.searchResultCell setSearchResultDescription:reallyLongString];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

- (void)testShouldHighlightMatchingSubstring {
    NSString* mediumTitleSubstring =
        [MediumSearchResultTitle substringToIndex:MediumSearchResultTitle.length * 0.3];
    [self populateTitleLabelWithString:MediumSearchResultTitle searchQuery:mediumTitleSubstring];
    [self.searchResultCell setSearchResultDescription:ShortSearchResultDescription];
    [self wmf_verifyViewAtScreenWidth:self.searchResultCell];
}

#pragma mark - Test Utils

- (void)populateTitleLabelWithString:(NSString*)titleText searchQuery:(NSString*)query {
    NSURL* titleURL =
        [NSURL URLWithString:[NSString stringWithFormat:@"//en.wikipedia.org/wiki/%@",
                              [titleText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    [self.searchResultCell setTitle:[[MWKTitle alloc] initWithURL:titleURL]
              highlightingSubstring:query];
}

@end
