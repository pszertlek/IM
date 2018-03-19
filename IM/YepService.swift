//
//  YepService.swift
//  IM
//
//  Created by apple on 2018/2/23.
//  Copyright © 2018年 Pszertlek. All rights reserved.
//

import Foundation

#if STAGING
    public let yepHost = "park-staging.catchchatchina.com"
    public let yepBaseURL = NSURL(string: "https://park-staging.catchchatchina.com/api")!
    public let fayeBaseURL = NSURL(string: "wss://faye-staging.catchchatchina.com/faye")!
#else
    public let yepHost = "soyep.com"
    public let yepBaseURL = NSURL(string: "https://api.soyep.com")!
    public let fayeBaseURL = NSURL(string: "wss://faye.catchchatchina.com/faye")!
#endif
