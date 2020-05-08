//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

#import "TSCall.h"
#import "TSContactThread.h"
#import <SignalCoreKit/NSDate+OWS.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSString *NSStringFromCallType(RPRecentCallType callType)
{
    switch (callType) {
        case RPRecentCallTypeIncoming:
            return @"RPRecentCallTypeIncoming";
        case RPRecentCallTypeOutgoing:
            return @"RPRecentCallTypeOutgoing";
        case RPRecentCallTypeIncomingMissed:
            return @"RPRecentCallTypeIncomingMissed";
        case RPRecentCallTypeOutgoingIncomplete:
            return @"RPRecentCallTypeOutgoingIncomplete";
        case RPRecentCallTypeIncomingIncomplete:
            return @"RPRecentCallTypeIncomingIncomplete";
        case RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity:
            return @"RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity";
        case RPRecentCallTypeIncomingDeclined:
            return @"RPRecentCallTypeIncomingDeclined";
        case RPRecentCallTypeOutgoingMissed:
            return @"RPRecentCallTypeOutgoingMissed";
        case RPRecentCallTypeIncomingAnsweredElsewhere:
            return @"RPRecentCallTypeIncomingAnsweredElsewhere";
        case RPRecentCallTypeIncomingDeclinedElsewhere:
            return @"RPRecentCallTypeIncomingDeclinedElsewhere";
        case RPRecentCallTypeIncomingBusyElsewhere:
            return @"RPRecentCallTypeIncomingBusyElsewhere";
    }
}

NSUInteger TSCallCurrentSchemaVersion = 1;

@interface TSCall ()

@property (nonatomic, getter=wasRead) BOOL read;

@property (nonatomic, readonly) NSUInteger callSchemaVersion;

@property (nonatomic) RPRecentCallType callType;

@end

#pragma mark -

@implementation TSCall

- (instancetype)initWithCallType:(RPRecentCallType)callType
                        inThread:(TSContactThread *)thread
                 sentAtTimestamp:(uint64_t)sentAtTimestamp
{
    self = [super initInteractionWithTimestamp:sentAtTimestamp inThread:thread];

    if (!self) {
        return self;
    }

    _callSchemaVersion = TSCallCurrentSchemaVersion;
    _callType = callType;

    // Ensure users are notified of missed calls.
    BOOL isIncomingMissed = (_callType == RPRecentCallTypeIncomingMissed
        || _callType == RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity);
    if (isIncomingMissed) {
        _read = NO;
    } else {
        _read = YES;
    }

    return self;
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                        callType:(RPRecentCallType)callType
                            read:(BOOL)read
{
    self = [super initWithGrdbId:grdbId
                        uniqueId:uniqueId
               receivedAtTimestamp:receivedAtTimestamp
                            sortId:sortId
                         timestamp:timestamp
                    uniqueThreadId:uniqueThreadId];

    if (!self) {
        return self;
    }

    _callType = callType;
    _read = read;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    if (self.callSchemaVersion < 1) {
        // Assume user has already seen any call that predate read-tracking
        _read = YES;
    }

    _callSchemaVersion = TSCallCurrentSchemaVersion;

    return self;
}

- (OWSInteractionType)interactionType
{
    return OWSInteractionType_Call;
}

- (NSString *)previewTextWithTransaction:(SDSAnyReadTransaction *)transaction
{
    // We don't actually use the `transaction` but other sibling classes do.
    switch (_callType) {
        case RPRecentCallTypeIncoming:
            return NSLocalizedString(@"INCOMING_CALL_ANSWERED", @"info message text in conversation view");
        case RPRecentCallTypeOutgoing:
            return NSLocalizedString(@"OUTGOING_CALL", @"info message text in conversation view");
        case RPRecentCallTypeIncomingMissed:
            return NSLocalizedString(@"MISSED_CALL", @"info message text in conversation view");
        case RPRecentCallTypeOutgoingIncomplete:
            return NSLocalizedString(@"OUTGOING_INCOMPLETE_CALL", @"info message text in conversation view");
        case RPRecentCallTypeIncomingIncomplete:
            return NSLocalizedString(@"INCOMING_INCOMPLETE_CALL", @"info message text in conversation view");
        case RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity:
            return NSLocalizedString(@"INFO_MESSAGE_MISSED_CALL_DUE_TO_CHANGED_IDENITY", @"info message text shown in conversation view");
        case RPRecentCallTypeIncomingDeclined:
            return NSLocalizedString(@"INCOMING_DECLINED_CALL",
                                     @"info message recorded in conversation history when local user declined a call");
        case RPRecentCallTypeOutgoingMissed:
            return NSLocalizedString(@"OUTGOING_MISSED_CALL",
                @"info message recorded in conversation history when local user tries and fails to call another user.");
        case RPRecentCallTypeIncomingAnsweredElsewhere:
            return NSLocalizedString(@"INCOMING_CALL_ANSWERED_ELSEWHERE",
                @"info message recorded in conversation history when a call was answered from another device");
        case RPRecentCallTypeIncomingDeclinedElsewhere:
            return NSLocalizedString(@"INCOMING_CALL_DECLINED_ELSEWHERE",
                @"info message recorded in conversation history when a call was declined from another device");
        case RPRecentCallTypeIncomingBusyElsewhere:
            return NSLocalizedString(@"INCOMING_CALL_BUSY_ELSEWHERE",
                @"info message recorded in conversation history when a call was missed due to an active call on "
                @"another device");
    }
}

#pragma mark - OWSReadTracking

- (uint64_t)expireStartedAt
{
    return 0;
}

- (BOOL)shouldAffectUnreadCounts
{
    return YES;
}

- (void)markAsReadAtTimestamp:(uint64_t)readTimestamp
                       thread:(TSThread *)thread
                 circumstance:(OWSReadCircumstance)circumstance
                  transaction:(SDSAnyWriteTransaction *)transaction
{

    OWSAssertDebug(transaction);

    if (self.read) {
        return;
    }

    OWSLogDebug(@"marking as read uniqueId: %@ which has timestamp: %llu", self.uniqueId, self.timestamp);

    [self anyUpdateCallWithTransaction:transaction
                                 block:^(TSCall *call) {
                                     call.read = YES;
                                 }];

    // Ignore `circumstance` - we never send read receipts for calls.
}

#pragma mark - Methods

- (void)updateCallType:(RPRecentCallType)callType
{
    [self.databaseStorage writeWithBlock:^(SDSAnyWriteTransaction *transaction) {
        [self updateCallType:callType transaction:transaction];
    }];
}

- (void)updateCallType:(RPRecentCallType)callType transaction:(SDSAnyWriteTransaction *)transaction
{
    OWSAssertDebug(transaction);

    OWSLogInfo(@"updating call type of call: %@ -> %@ with uniqueId: %@ which has timestamp: %llu",
        NSStringFromCallType(_callType),
        NSStringFromCallType(callType),
        self.uniqueId,
        self.timestamp);

    [self anyUpdateCallWithTransaction:transaction
                                 block:^(TSCall *call) {
                                     call.callType = callType;
                                 }];
}

@end

NS_ASSUME_NONNULL_END
