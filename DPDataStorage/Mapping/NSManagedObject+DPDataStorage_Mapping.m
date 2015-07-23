//
//  NSManagedObject+DPDataStorage_Mapping.m
//  DP Commons
//
//  Created by Dmitriy Petrusevich on 06/05/15.
//  Copyright (c) 2015 Dmitriy Petrusevich. All rights reserved.
//

#import "NSManagedObject+DPDataStorage_Mapping.h"
#import "NSManagedObject+DataStorage.h"
#import "DPDataStorage.h"


static NSString * const kUniqueKey = @"uniqueKey";
static NSString * const kImportKey = @"importKey";


@implementation NSManagedObject (DPDataStorage_Mapping)

+ (id)transformImportValue:(id)value importKey:(NSString *)importKey propertyDescription:(NSPropertyDescription *)propertyDescription {
    return value;
}

+ (NSArray *)updateWithArray:(NSArray *)array inContext:(NSManagedObjectContext *)context error:(NSError **)out_error {
    NSError *error = nil;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];

    if ([array isKindOfClass:[NSArray class]] == NO) {
        NSString *details = [NSString stringWithFormat:@"Invalid root import object (expected: %@, actual: %@) for class: %@", NSStringFromClass([NSArray class]), NSStringFromClass([array class]), NSStringFromClass([self class])];
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
    }
    else {
        NSEntityDescription *entityDescription = [context entityDescriptionForManagedObjectClass:[self class]];
        NSDictionary *entityAttributes = [entityDescription attributesByName];

        NSString *entityUniqueKey = entityDescription.userInfo[kUniqueKey];
        NSAttributeDescription *uniqueAttr = entityUniqueKey ? entityAttributes[entityUniqueKey] : nil;
        NSString *importUniqueKey = uniqueAttr.userInfo[kImportKey];
        Class uniqueValueClass = uniqueAttr ? NSClassFromString(uniqueAttr.attributeValueClassName) : nil;

        if (importUniqueKey != nil || entityUniqueKey == nil) {
            for (NSDictionary *itemInfo in array) {
                if ([itemInfo isKindOfClass:[NSDictionary class]] == NO) {
                    NSString *details = [NSString stringWithFormat:@"Invalid import object (expected: %@, actual: %@) for class: %@", NSStringFromClass([NSDictionary class]), NSStringFromClass([itemInfo class]), NSStringFromClass([self class])];
                    error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
                }
                else {
                    if (entityUniqueKey == nil) {
                        [result addObject:[NSNull null]];
                    }
                    else {
                        id value = [self transformImportValue:itemInfo[importUniqueKey] importKey:importUniqueKey propertyDescription:uniqueAttr];
                        if (value) {
                            if ([value isKindOfClass:uniqueValueClass]) {
                                NSManagedObject *existObject = [self entryWithValue:value forKey:entityUniqueKey inContext:context];
                                [result addObject:existObject ? existObject : [NSNull null]];
                            }
                            else {
                                NSString *details = [NSString stringWithFormat:@"Invalid import value class (expected: %@, actual: %@) for key: '%@' in object: '%@'", uniqueAttr.attributeValueClassName, NSStringFromClass([value class]), entityUniqueKey, NSStringFromClass([self class])];
                                error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
                            }
                        }
                        else {
                            NSString *details = [NSString stringWithFormat:@"Import value for unique key cannot be 'nil' (class: %@)", NSStringFromClass([self class])];
                            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
                        }
                    }
                }
            }
        }
        else {
            NSString *details = [NSString stringWithFormat:@"Not found '%@' for '%@' in class: %@", kImportKey, kUniqueKey, NSStringFromClass([self class])];
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
        }

        if (error == nil) {
            NSAssert(result.count == array.count, @"Invalid result array length");

            for (NSInteger i = 0; i < array.count; i++) {
                NSDictionary *itemInfo = array[i];

                NSManagedObject *object = nil;
                if (result[i] == [NSNull null]) {
                    object = [self insertInContext:context];
                    [result replaceObjectAtIndex:i withObject:object];
                }

                if (![object updateAttributesWithDictionary:itemInfo error:&error] || ![object updateRelationshipsWithDictionary:itemInfo error:&error]) {
                    break;
                }
            }
        }
    }

    if (error && out_error) *out_error = error;
    return (error == nil) ? result : nil;
}

+ (instancetype)updateWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context error:(NSError **)out_error {
    NSError *error = nil;
    NSManagedObject *result = nil;

    if ([dictionary isKindOfClass:[NSDictionary class]] == NO) {
        NSString *details = [NSString stringWithFormat:@"Invalid root import object (expected: %@, actual: %@) for class: %@", NSStringFromClass([NSDictionary class]), NSStringFromClass([dictionary class]), NSStringFromClass([self class])];
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
    }
    else {
        NSEntityDescription *entityDescription = [context entityDescriptionForManagedObjectClass:[self class]];
        NSDictionary *entityAttributes = [entityDescription attributesByName];

        NSString *entityUniqueKey = entityDescription.userInfo[kUniqueKey];
        NSAttributeDescription *uniqueAttr = entityUniqueKey ? entityAttributes[entityUniqueKey] : nil;
        NSString *importUniqueKey = uniqueAttr.userInfo[kImportKey];

        if (importUniqueKey != nil) {
            Class valueClass = NSClassFromString(uniqueAttr.attributeValueClassName);
            id value = [self transformImportValue:dictionary[importUniqueKey] importKey:importUniqueKey propertyDescription:uniqueAttr];

            if (value) {
                if ([value isKindOfClass:valueClass]) {
                    result = [self entryWithValue:value forKey:entityUniqueKey inContext:context];
                    if (result == nil) {
                        result = [self insertInContext:context];
                        [result setValue:value forKey:entityUniqueKey];
                    }
                }
                else {
                    NSString *details = [NSString stringWithFormat:@"Invalid import value class (expected: %@, actual: %@) for key: '%@' in object: '%@'", uniqueAttr.attributeValueClassName, NSStringFromClass([value class]), entityUniqueKey, NSStringFromClass([self class])];
                    error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
                }
            }
            else {
                NSString *details = [NSString stringWithFormat:@"Import value for unique key cannot be 'nil' (class: %@)", NSStringFromClass([self class])];
                error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
            }
        }
        else if (entityUniqueKey == nil) {
            result = [self insertInContext:context];
        }
        else {
            NSString *details = [NSString stringWithFormat:@"Not found '%@' for '%@' in class: %@", kImportKey, kUniqueKey, NSStringFromClass([self class])];
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}];
        }

        if (error == nil) {
            [result updateAttributesWithDictionary:dictionary error:&error];
        }

        if (error == nil) {
            [result updateRelationshipsWithDictionary:dictionary error:&error];
        }
    }

    if (error && out_error) *out_error = error;
    return (error == nil) ? result : nil;
}

- (BOOL)updateAttributesWithDictionary:(NSDictionary *)dictionary error:(NSError *__autoreleasing *)out_error {
    NSMutableArray *errors = [NSMutableArray array];
    NSDictionary *entityAttributes = [self.entity attributesByName];

    for (NSString *attributeName in entityAttributes) {
        NSAttributeDescription *attributeDescription = entityAttributes[attributeName];
        NSString *importKey = attributeDescription.userInfo[kImportKey];
        id importValue = importKey ? dictionary[importKey] : nil;
        id value = importValue ? [[self class] transformImportValue:importValue importKey:importKey propertyDescription:attributeDescription] : nil;

        if (value != nil) {
            if (value == [NSNull null]) {
                [self setValue:nil forKey:attributeName];
            }
            else if (attributeDescription.attributeType == NSTransformableAttributeType) {
                [self setValue:value forKey:attributeName];
            }
            else {
                Class valueClass = NSClassFromString(attributeDescription.attributeValueClassName);
                if ([value isKindOfClass:valueClass]) {
                    [self setValue:value forKey:attributeName];
                }
                else {
                    NSString *details = [NSString stringWithFormat:@"Invalid import value class (expected: %@, actual: %@) for key: '%@' in object: '%@'", attributeDescription.attributeValueClassName, NSStringFromClass([value class]), attributeName, NSStringFromClass([self class])];
                    [errors addObject:[NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}]];
                }
            }
        }
    }

    NSError *error = nil;
    if (errors.count) {
        error = (errors.count == 1) ? [errors firstObject] : [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSDetailedErrorsKey: errors}];
    }

    if (error && out_error) *out_error = error;
    return (error == nil);
}

- (BOOL)updateRelationshipsWithDictionary:(NSDictionary *)dictionary error:(NSError **)out_error {
    NSMutableArray *errors = [NSMutableArray array];
    NSDictionary *entityRelationships = [self.entity relationshipsByName];

    for (NSString *keyName in entityRelationships) {
        NSRelationshipDescription *relationshipDescription = entityRelationships[keyName];
        NSString *importKey = relationshipDescription.userInfo[kImportKey];
        id importValue = importKey ? dictionary[importKey] : nil;
        id value = importValue ? [[self class] transformImportValue:importValue importKey:importKey propertyDescription:relationshipDescription] : nil;

        if (value != nil) {
            Class valueClass = relationshipDescription.isToMany ? [NSArray class] : [NSDictionary class];
            Class relationClass = NSClassFromString(relationshipDescription.destinationEntity.managedObjectClassName);

            if (value == [NSNull null]) {
                [self setValue:nil forKey:keyName];
            }
            else if ([value isKindOfClass:valueClass]) {
                NSError *error = nil;

                if (valueClass == [NSDictionary class]) {
                    NSManagedObject *object = [relationClass updateWithDictionary:(NSDictionary *)value inContext:[self managedObjectContext] error:&error];
                    if (error == nil) {
                        [self setValue:object forKey:keyName];
                    }
                }
                else { //if (valueClass == [NSArray class]) {
                    NSMutableSet *set = [NSMutableSet set];

                    for (NSDictionary *info in value) {
                        NSManagedObject *object = [relationClass updateWithDictionary:(NSDictionary *)info inContext:[self managedObjectContext] error:&error];
                        if (object) [set addObject:object];
                        else break;
                    }

                    if (error == nil) {
                        [self setValue:set forKey:keyName];
                    }
                }

                if (error) {
                    [errors addObject:error];
                    break;
                }
            }
            else {
                NSString *details = [NSString stringWithFormat:@"Invalid import value class (expected: %@, actual: %@) for key: '%@' in object: '%@'", NSStringFromClass(valueClass), NSStringFromClass([value class]), keyName, NSStringFromClass([self class])];
                [errors addObject:[NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSLocalizedFailureReasonErrorKey: details}]];
            }
        }
    }

    NSError *error = nil;
    if (errors.count) {
        error = (errors.count == 1) ? [errors firstObject] : [NSError errorWithDomain:NSCocoaErrorDomain code:NSExternalRecordImportError userInfo:@{NSDetailedErrorsKey: errors}];
    }
    
    if (error && out_error) *out_error = error;
    return (error == nil);
}

@end