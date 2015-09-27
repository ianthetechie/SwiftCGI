//
//  http_parser_accessors.c
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/23/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

#include "http_parser_accessors.h"

const char* http_parser_get_method(struct http_parser *parser) {
    return http_method_str(parser->method);
}

const char* http_parser_get_error_name(struct http_parser *parser) {
    return http_errno_name(parser->http_errno);
}

const char* http_parser_get_error_description(struct http_parser *parser) {
    return http_errno_description(parser->http_errno);
}

unsigned int http_parser_get_status_code(struct http_parser *parser) {
    return parser->status_code;
}