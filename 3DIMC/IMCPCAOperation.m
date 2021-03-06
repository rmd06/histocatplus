//
//  IMCPCAOperation.m
//  IMCReader
//
//  Created by Raul Catena on 9/17/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCPCAOperation.h"
#import "pca.h"

@implementation IMCPCAOperation


-(NSString *)nameGiven{
    if(!_nameGiven){
        _nameGiven = [@"PCA_" stringByAppendingString:[NSString stringWithFormat:@"%@", [NSDate date]]];
    }
    return _nameGiven;
}

-(NSString *)description{
    if(self.opFinished == YES)return self.nameGiven;
    return [NSString stringWithFormat:@"%i/%i-%@", self.iterationCursor, self.numberOfCycles, self.nameGiven];
}

-(void)main{
    @autoreleasepool {
        reduce_data(self.inputData,
                    (int)self.numberOfVariables,
                    (int)self.numberOfValues,
                    self.outputData,
                    (int)self.numberOfOutputVariables);
        
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

@end
