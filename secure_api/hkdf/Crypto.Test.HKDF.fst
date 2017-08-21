module Crypto.Test.HKDF

open FStar.HyperStack.All

open FStar.UInt32
open FStar.Ghost
open FStar.Buffer

module ST = FStar.HyperStack.ST
module HH = FStar.HyperHeap
module HS = FStar.HyperStack

module HMAC = Crypto.HMAC

open Crypto.HKDF

#set-options "--lax"

(**
   https://tools.ietf.org/html/rfc5869#appendix-A.1

   Basic test case with SHA-256

   Hash = SHA-256
   IKM  = 0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b (22 octets)
   salt = 0x000102030405060708090a0b0c (13 octets)
   info = 0xf0f1f2f3f4f5f6f7f8f9 (10 octets)
   L    = 42

   PRK  = 0x077709362c2e32df0ddc3f0dc47bba63
          90b6c73bb50f9c3122ec844ad7c2b3e5 (32 octets)
   OKM  = 0x3cb25f25faacd57a90434f64d0362f2a
          2d2d0a90cf1a5a4c5db02d56ecc4c5bf
          34007208d5b887185865 (42 octets)
**)
val test_1: unit -> St unit
let test_1 () =
  let ikm = Buffer.createL [
    0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy;
    0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy;
    0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy
  ] in
  let ikmlen = 22ul in
  let salt = Buffer.createL [
    0x00uy; 0x01uy; 0x02uy; 0x03uy; 0x04uy; 0x05uy; 0x06uy; 0x07uy;
    0x08uy; 0x09uy; 0x0auy; 0x0buy; 0x0cuy;
  ] in
  let saltlen = 13ul in
  let info = Buffer.createL [
    0xf0uy; 0xf1uy; 0xf2uy; 0xf3uy; 0xf4uy; 0xf5uy; 0xf6uy; 0xf7uy;
    0xf8uy; 0xf9uy;
  ] in
  let infolen = 10ul in
  let len = 42ul in

  let prk = Buffer.createL [
    0x07uy; 0x77uy; 0x09uy; 0x36uy; 0x2cuy; 0x2euy; 0x32uy; 0xdfuy;
    0x0duy; 0xdcuy; 0x3fuy; 0x0duy; 0xc4uy; 0x7buy; 0xbauy; 0x63uy;
    0x90uy; 0xb6uy; 0xc7uy; 0x3buy; 0xb5uy; 0x0fuy; 0x9cuy; 0x31uy;
    0x22uy; 0xecuy; 0x84uy; 0x4auy; 0xd7uy; 0xc2uy; 0xb3uy; 0xe5uy;
  ] in
  let prklen = 32ul in
  let okm = Buffer.createL [
    0x3cuy; 0xb2uy; 0x5fuy; 0x25uy; 0xfauy; 0xacuy; 0xd5uy; 0x7auy;
    0x90uy; 0x43uy; 0x4fuy; 0x64uy; 0xd0uy; 0x36uy; 0x2fuy; 0x2auy;
    0x2duy; 0x2duy; 0x0auy; 0x90uy; 0xcfuy; 0x1auy; 0x5auy; 0x4cuy;
    0x5duy; 0xb0uy; 0x2duy; 0x56uy; 0xecuy; 0xc4uy; 0xc5uy; 0xbfuy;
    0x34uy; 0x00uy; 0x72uy; 0x08uy; 0xd5uy; 0xb8uy; 0x87uy; 0x18uy;
    0x58uy; 0x65uy;
  ] in

  let prk' = Buffer.create 0uy prklen in
  hkdf_extract HMAC.SHA256 prk' salt saltlen ikm ikmlen;
  TestLib.compare_and_print (C.string_of_literal "HKDF-SHA-256-Extract Test 1: ")
    prk prk' prklen;

  let okm' = Buffer.create 0uy len in
  hkdf_expand HMAC.SHA256 okm' prk prklen info infolen len;
  TestLib.compare_and_print (C.string_of_literal "HKDF-SHA-256-Expand Test 1: ")
    okm okm' len


(**
   https://tools.ietf.org/html/rfc5869#appendix-A.2

   Test with SHA-256 and longer inputs/outputs

   Hash = SHA-256
   IKM  = 0x000102030405060708090a0b0c0d0e0f
          101112131415161718191a1b1c1d1e1f
          202122232425262728292a2b2c2d2e2f
          303132333435363738393a3b3c3d3e3f
          404142434445464748494a4b4c4d4e4f (80 octets)
   salt = 0x606162636465666768696a6b6c6d6e6f
          707172737475767778797a7b7c7d7e7f
          808182838485868788898a8b8c8d8e8f
          909192939495969798999a9b9c9d9e9f
          a0a1a2a3a4a5a6a7a8a9aaabacadaeaf (80 octets)
   info = 0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebf
          c0c1c2c3c4c5c6c7c8c9cacbcccdcecf
          d0d1d2d3d4d5d6d7d8d9dadbdcdddedf
          e0e1e2e3e4e5e6e7e8e9eaebecedeeef
          f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff (80 octets)
   L    = 82

   PRK  = 0x06a6b88c5853361a06104c9ceb35b45c
          ef760014904671014a193f40c15fc244 (32 octets)
   OKM  = 0xb11e398dc80327a1c8e7f78c596a4934
          4f012eda2d4efad8a050cc4c19afa97c
          59045a99cac7827271cb41c65e590e09
          da3275600c2f09b8367793a9aca3db71
          cc30c58179ec3e87c14c01d5c1f3434f
          1d87 (82 octets)
**)
val test_2: unit -> St unit
let test_2 () =
  let ikm = Buffer.createL [
    0x00uy; 0x01uy; 0x02uy; 0x03uy; 0x04uy; 0x05uy; 0x06uy; 0x07uy;
    0x08uy; 0x09uy; 0x0auy; 0x0buy; 0x0cuy; 0x0duy; 0x0euy; 0x0fuy;
    0x10uy; 0x11uy; 0x12uy; 0x13uy; 0x14uy; 0x15uy; 0x16uy; 0x17uy;
    0x18uy; 0x19uy; 0x1auy; 0x1buy; 0x1cuy; 0x1duy; 0x1euy; 0x1fuy;
    0x20uy; 0x21uy; 0x22uy; 0x23uy; 0x24uy; 0x25uy; 0x26uy; 0x27uy;
    0x28uy; 0x29uy; 0x2auy; 0x2buy; 0x2cuy; 0x2duy; 0x2euy; 0x2fuy;
    0x30uy; 0x31uy; 0x32uy; 0x33uy; 0x34uy; 0x35uy; 0x36uy; 0x37uy;
    0x38uy; 0x39uy; 0x3auy; 0x3buy; 0x3cuy; 0x3duy; 0x3euy; 0x3fuy;
    0x40uy; 0x41uy; 0x42uy; 0x43uy; 0x44uy; 0x45uy; 0x46uy; 0x47uy;
    0x48uy; 0x49uy; 0x4auy; 0x4buy; 0x4cuy; 0x4duy; 0x4euy; 0x4fuy;
  ] in
  let ikmlen = 80ul in
  let salt = Buffer.createL [
    0x60uy; 0x61uy; 0x62uy; 0x63uy; 0x64uy; 0x65uy; 0x66uy; 0x67uy;
    0x68uy; 0x69uy; 0x6auy; 0x6buy; 0x6cuy; 0x6duy; 0x6euy; 0x6fuy;
    0x70uy; 0x71uy; 0x72uy; 0x73uy; 0x74uy; 0x75uy; 0x76uy; 0x77uy;
    0x78uy; 0x79uy; 0x7auy; 0x7buy; 0x7cuy; 0x7duy; 0x7euy; 0x7fuy;
    0x80uy; 0x81uy; 0x82uy; 0x83uy; 0x84uy; 0x85uy; 0x86uy; 0x87uy;
    0x88uy; 0x89uy; 0x8auy; 0x8buy; 0x8cuy; 0x8duy; 0x8euy; 0x8fuy;
    0x90uy; 0x91uy; 0x92uy; 0x93uy; 0x94uy; 0x95uy; 0x96uy; 0x97uy;
    0x98uy; 0x99uy; 0x9auy; 0x9buy; 0x9cuy; 0x9duy; 0x9euy; 0x9fuy;
    0xa0uy; 0xa1uy; 0xa2uy; 0xa3uy; 0xa4uy; 0xa5uy; 0xa6uy; 0xa7uy;
    0xa8uy; 0xa9uy; 0xaauy; 0xabuy; 0xacuy; 0xaduy; 0xaeuy; 0xafuy;
  ] in
  let saltlen = 80ul in
  let info = Buffer.createL [
    0xb0uy; 0xb1uy; 0xb2uy; 0xb3uy; 0xb4uy; 0xb5uy; 0xb6uy; 0xb7uy;
    0xb8uy; 0xb9uy; 0xbauy; 0xbbuy; 0xbcuy; 0xbduy; 0xbeuy; 0xbfuy;
    0xc0uy; 0xc1uy; 0xc2uy; 0xc3uy; 0xc4uy; 0xc5uy; 0xc6uy; 0xc7uy;
    0xc8uy; 0xc9uy; 0xcauy; 0xcbuy; 0xccuy; 0xcduy; 0xceuy; 0xcfuy;
    0xd0uy; 0xd1uy; 0xd2uy; 0xd3uy; 0xd4uy; 0xd5uy; 0xd6uy; 0xd7uy;
    0xd8uy; 0xd9uy; 0xdauy; 0xdbuy; 0xdcuy; 0xdduy; 0xdeuy; 0xdfuy;
    0xe0uy; 0xe1uy; 0xe2uy; 0xe3uy; 0xe4uy; 0xe5uy; 0xe6uy; 0xe7uy;
    0xe8uy; 0xe9uy; 0xeauy; 0xebuy; 0xecuy; 0xeduy; 0xeeuy; 0xefuy;
    0xf0uy; 0xf1uy; 0xf2uy; 0xf3uy; 0xf4uy; 0xf5uy; 0xf6uy; 0xf7uy;
    0xf8uy; 0xf9uy; 0xfauy; 0xfbuy; 0xfcuy; 0xfduy; 0xfeuy; 0xffuy;
  ] in
  let infolen = 80ul in
  let len = 82ul in

  let prk = Buffer.createL [
    0x06uy; 0xa6uy; 0xb8uy; 0x8cuy; 0x58uy; 0x53uy; 0x36uy; 0x1auy;
    0x06uy; 0x10uy; 0x4cuy; 0x9cuy; 0xebuy; 0x35uy; 0xb4uy; 0x5cuy;
    0xefuy; 0x76uy; 0x00uy; 0x14uy; 0x90uy; 0x46uy; 0x71uy; 0x01uy;
    0x4auy; 0x19uy; 0x3fuy; 0x40uy; 0xc1uy; 0x5fuy; 0xc2uy; 0x44uy;
  ] in
  let prklen = 32ul in
  let okm = Buffer.createL [
    0xb1uy; 0x1euy; 0x39uy; 0x8duy; 0xc8uy; 0x03uy; 0x27uy; 0xa1uy;
    0xc8uy; 0xe7uy; 0xf7uy; 0x8cuy; 0x59uy; 0x6auy; 0x49uy; 0x34uy;
    0x4fuy; 0x01uy; 0x2euy; 0xdauy; 0x2duy; 0x4euy; 0xfauy; 0xd8uy;
    0xa0uy; 0x50uy; 0xccuy; 0x4cuy; 0x19uy; 0xafuy; 0xa9uy; 0x7cuy;
    0x59uy; 0x04uy; 0x5auy; 0x99uy; 0xcauy; 0xc7uy; 0x82uy; 0x72uy;
    0x71uy; 0xcbuy; 0x41uy; 0xc6uy; 0x5euy; 0x59uy; 0x0euy; 0x09uy;
    0xdauy; 0x32uy; 0x75uy; 0x60uy; 0x0cuy; 0x2fuy; 0x09uy; 0xb8uy;
    0x36uy; 0x77uy; 0x93uy; 0xa9uy; 0xacuy; 0xa3uy; 0xdbuy; 0x71uy;
    0xccuy; 0x30uy; 0xc5uy; 0x81uy; 0x79uy; 0xecuy; 0x3euy; 0x87uy;
    0xc1uy; 0x4cuy; 0x01uy; 0xd5uy; 0xc1uy; 0xf3uy; 0x43uy; 0x4fuy;
    0x1duy; 0x87uy;
  ] in

  let salt' = Buffer.create 0uy HMAC.(block_size SHA256) in
  Hacl.Hash.SHA2_256.hash salt' salt saltlen;
  let zeros = Buffer.sub salt'
    HMAC.(hash_size SHA256) HMAC.(block_size SHA256 -^ hash_size SHA256) in
  Buffer.fill zeros 0uy HMAC.(block_size SHA256 -^ hash_size SHA256);
  let saltlen' = HMAC.(block_size SHA256) in

  let prk' = Buffer.create 0uy prklen in
  hkdf_extract HMAC.SHA256 prk' salt' saltlen' ikm ikmlen;
  TestLib.compare_and_print (C.string_of_literal "HKDF-SHA-256-Extract Test 2: ")
    prk prk' prklen;

  let okm' = Buffer.create 0uy len in
  hkdf_expand HMAC.SHA256 okm' prk prklen info infolen len;
  TestLib.compare_and_print (C.string_of_literal "HKDF-SHA-256-Expand Test 2: ")
    okm okm' len


(**
   https://tools.ietf.org/html/rfc5869#appendix-A.3

   Test with SHA-256 and zero-length salt/info

   Hash = SHA-256
   IKM  = 0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b (22 octets)
   salt = (0 octets)
   info = (0 octets)
   L    = 42

   PRK  = 0x19ef24a32c717b167f33a91d6f648bdf
          96596776afdb6377ac434c1c293ccb04 (32 octets)
   OKM  = 0x8da4e775a563c18f715f802a063c5a31
          b8a11f5c5ee1879ec3454e5f3c738d2d
**)
val test_3: unit -> St unit
let test_3 () =
  let ikm = Buffer.createL [
    0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy;
    0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy;
    0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy; 0x0buy
  ] in
  let ikmlen = 22ul in
  let salt = Buffer.create 0uy 0ul in
  let saltlen = 0ul in
  let info = Buffer.create 0uy 0ul in
  let infolen = 0ul in
  let len = 42ul in

  let prk = Buffer.createL [
    0x19uy; 0xefuy; 0x24uy; 0xa3uy; 0x2cuy; 0x71uy; 0x7buy; 0x16uy;
    0x7fuy; 0x33uy; 0xa9uy; 0x1duy; 0x6fuy; 0x64uy; 0x8buy; 0xdfuy;
    0x96uy; 0x59uy; 0x67uy; 0x76uy; 0xafuy; 0xdbuy; 0x63uy; 0x77uy;
    0xacuy; 0x43uy; 0x4cuy; 0x1cuy; 0x29uy; 0x3cuy; 0xcbuy; 0x04uy;
  ] in
  let prklen = 32ul in
  let okm = Buffer.createL [
    0x8duy; 0xa4uy; 0xe7uy; 0x75uy; 0xa5uy; 0x63uy; 0xc1uy; 0x8fuy;
    0x71uy; 0x5fuy; 0x80uy; 0x2auy; 0x06uy; 0x3cuy; 0x5auy; 0x31uy;
    0xb8uy; 0xa1uy; 0x1fuy; 0x5cuy; 0x5euy; 0xe1uy; 0x87uy; 0x9euy;
    0xc3uy; 0x45uy; 0x4euy; 0x5fuy; 0x3cuy; 0x73uy; 0x8duy; 0x2duy;
    0x9duy; 0x20uy; 0x13uy; 0x95uy; 0xfauy; 0xa4uy; 0xb6uy; 0x1auy;
    0x96uy; 0xc8uy
  ] in

  let salt' = Buffer.create 0uy HMAC.(block_size SHA256) in
  let saltlen = HMAC.(block_size SHA256) in

  let prk' = Buffer.create 0uy prklen in
  hkdf_extract HMAC.SHA256 prk' salt' saltlen ikm ikmlen;
  TestLib.compare_and_print (C.string_of_literal "HKDF-SHA-256-Extract Test 3: ")
    prk prk' prklen;

  let okm' = Buffer.create 0uy len in
  hkdf_expand HMAC.SHA256 okm' prk prklen info infolen len;
  TestLib.compare_and_print (C.string_of_literal "HKDF-SHA-256-Expand Test 3: ")
    okm okm' len


val main: unit -> St FStar.Int32.t
let main () =
  test_1 ();
  test_2 ();
  test_3 ();
  C.exit_success

let _ = main ()
