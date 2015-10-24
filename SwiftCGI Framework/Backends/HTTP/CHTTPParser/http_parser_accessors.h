//
//  http_parser_accessors.h
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/23/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

#ifndef http_parser_accessors_h
#define http_parser_accessors_h

#include "http-parser/http_parser.h"

const char* http_parser_get_method(struct http_parser *parser);

const char* http_parser_get_error_name(struct http_parser *parser);

const char* http_parser_get_error_description(struct http_parser *parser);

unsigned int http_parser_get_status_code(struct http_parser *parser);

#endif /* http_parser_accessors_h */
