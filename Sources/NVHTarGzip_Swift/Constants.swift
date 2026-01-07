//
//  Constants.swift
//  NVHTarGzip-Swift
//
//  Created by roxx990 on 07/01/2026.
//  Copyright © 2026 roxx990. All rights reserved.
//
//  A pure-Swift reimplementation of NVHTarGzip, supporting .tar, .gz, and .tar.gz archives
//  with progress tracking on Apple platforms.
//

import Foundation

let TAR_BLOCK_SIZE: UInt64 = 512
let TAR_TYPE_POSITION: UInt64 = 156
let TAR_NAME_POSITION: UInt64 = 0
let TAR_NAME_SIZE: UInt64 = 100
let TAR_SIZE_POSITION: UInt64 = 124
let TAR_SIZE_SIZE: UInt64 = 12
let TAR_MAX_BLOCK_LOAD_IN_MEMORY: UInt64 = 100

let USTAR_name_offset = 0
let USTAR_name_size = 100
let USTAR_mode_offset = 100
let USTAR_mode_size = 8
let USTAR_uid_offset = 108
let USTAR_uid_size = 8
let USTAR_gid_offset = 116
let USTAR_gid_size = 8
let USTAR_size_offset = 124
let USTAR_size_size = 12
let USTAR_mtime_offset = 136
let USTAR_mtime_size = 12
let USTAR_checksum_offset = 148
let USTAR_checksum_size = 8
let USTAR_typeflag_offset = 156
let USTAR_typeflag_size = 1
let USTAR_linkname_offset = 157
let USTAR_linkname_size = 100
let USTAR_magic_offset = 257
let USTAR_magic_size = 6
let USTAR_version_offset = 263
let USTAR_version_size = 2
let USTAR_uname_offset = 265
let USTAR_uname_size = 32
let USTAR_gname_offset = 297
let USTAR_gname_size = 32
let USTAR_rdevmajor_offset = 329
let USTAR_rdevmajor_size = 8
let USTAR_rdevminor_offset = 337
let USTAR_rdevminor_size = 8
let USTAR_prefix_offset = 345
let USTAR_prefix_size = 155

let TAR_ERROR_DOMAIN = "io.nvh.targzip.tar.error"
let TAR_ERROR_CODE_BAD_BLOCK = 1
let TAR_ERROR_CODE_SOURCE_NOT_FOUND = 2

extension String {
    var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }
    
    var pathExtension: String {
        (self as NSString).pathExtension
    }
    
    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }

    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    func appendingPathComponent(_ str: String) -> String {
        (self as NSString).appendingPathComponent(str)
    }

    func appendingPathExtension(_ str: String) -> String {
        (self as NSString).appendingPathExtension(str) ?? self
    }
}

extension FileManager {
    func fileSizeOfItem(atPath path: String) -> UInt64 {
        do {
            let attributes = try attributesOfItem(atPath: path)
            return attributes[.size] as? UInt64 ?? 0
        } catch {
            return 0
        }
    }

    func fileSizeOfDirectory(atPath path: String) -> UInt64 {
        var size: UInt64 = 0
        if let enumerator = enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) {
            for case let url as URL in enumerator {
                let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey])
                if resourceValues?.isDirectory == false {
                    size += UInt64(resourceValues?.totalFileAllocatedSize ?? 0)
                }
            }
        }
        return size
    }
}
