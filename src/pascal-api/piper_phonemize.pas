{ piper_phonemize.pas }
{ Pascal bindings for the piper-phonemize C API. }
{
  Copyright (c) 2026  Xiaomi Corporation

  Usage:
    uses piper_phonemize;

  Supports both static and dynamic linking:
    - Default (Linux/macOS): static linking
    - Define PIPER_PHONEMIZE_USE_SHARED_LIBS: dynamic linking
    - Windows: always dynamic linking (DLL)
}
unit piper_phonemize;

{$mode objfpc}{$H+}
{$PACKRECORDS C}

interface

uses
  Classes,
  SysUtils;

type
  { Array of phoneme code points (Unicode) }
  TPhonemeArray = array of Integer;

  { Result handle -- opaque pointer to the C PiperPhonemizeResult struct }
  TPiperPhonemizeResult = class
  private
    FHandle: Pointer;
  public
    constructor Create(AHandle: Pointer);
    destructor Destroy; override;

    { Number of sentences in the result }
    function GetNumSentences: Integer;

    { Number of phonemes in a given sentence (0-based index). Returns -1 if out of range. }
    function GetNumPhonemes(SentenceId: Integer): Integer;

    { Get phonemes for a given sentence as an array of Unicode code points. }
    function GetPhonemes(SentenceId: Integer): TPhonemeArray;
  end;

{
  Initialize espeak-ng with the given data directory.
  Must be called before Phonemize().
  Safe to call multiple times; only the first call takes effect.

  @param DataDir  Path to the espeak-ng-data directory.
  @return Sample rate (22050) on first call, 0 on subsequent calls, or -1 on failure.
}
function PiperPhonemizeInitialize(const DataDir: AnsiString): Integer;

{
  Phonemize text using espeak-ng.
  Caller must free the result with TPiperPhonemizeResult.Free().

  @param Text   The text to phonemize (UTF-8).
  @param Voice  The espeak-ng voice to use (e.g. 'en-us'). Pass '' for default.
  @return A TPiperPhonemizeResult object, or nil on failure.
}
function PiperPhonemizeText(const Text: AnsiString; const Voice: AnsiString): TPiperPhonemizeResult;

{
  Return the piper-phonemize version string.
}
function PiperPhonemizeGetVersionStr: AnsiString;

implementation

{ ---------------------------------------------------------------------------
  C types
  --------------------------------------------------------------------------- }

type
  cint32 = Int32;
  cuint32 = UInt32;
  pcuint32 = ^cuint32;

  { Opaque pointer to PiperPhonemizeResult }
  PPiperPhonemizeResult = Pointer;

{ ---------------------------------------------------------------------------
  C function declarations
  --------------------------------------------------------------------------- }

const
{$if defined(WINDOWS)}
  PiperPhonemizeLibName = 'piper_phonemize_core.dll';
{$elseif not defined(PIPER_PHONEMIZE_USE_SHARED_LIBS)}
  PiperPhonemizeLibName = '';  { static link }
{$else}
  PiperPhonemizeLibName = 'piper_phonemize_core';
  {$linklib piper_phonemize_core}
{$endif}

function PiperPhonemizeGetVersionStr_c: PAnsiChar; cdecl;
  external PiperPhonemizeLibName name 'PiperPhonemizeGetVersionStr';

function PiperPhonemizeInitialize_c(const data_dir: PAnsiChar): cint32; cdecl;
  external PiperPhonemizeLibName name 'PiperPhonemizeInitialize';

function PiperPhonemizeText_c(const text: PAnsiChar; const voice: PAnsiChar): PPiperPhonemizeResult; cdecl;
  external PiperPhonemizeLibName name 'PiperPhonemizeText';

function PiperPhonemizeResultGetNumSentences_c(const result: PPiperPhonemizeResult): cint32; cdecl;
  external PiperPhonemizeLibName name 'PiperPhonemizeResultGetNumSentences';

function PiperPhonemizeResultGetNumPhonemes_c(const result: PPiperPhonemizeResult; sentence_id: cint32): cint32; cdecl;
  external PiperPhonemizeLibName name 'PiperPhonemizeResultGetNumPhonemes';

function PiperPhonemizeResultGetPhonemes_c(const result: PPiperPhonemizeResult; sentence_id: cint32): pcuint32; cdecl;
  external PiperPhonemizeLibName name 'PiperPhonemizeResultGetPhonemes';

procedure PiperPhonemizeDestroyResult_c(result: PPiperPhonemizeResult); cdecl;
  external PiperPhonemizeLibName name 'PiperPhonemizeDestroyResult';

{ ---------------------------------------------------------------------------
  Static linking: pull in required libraries
  --------------------------------------------------------------------------- }

{$if not defined(WINDOWS) and not defined(PIPER_PHONEMIZE_USE_SHARED_LIBS)}
{$linklib piper_phonemize_core}
{$linklib espeak-ng}
{$linklib ucd}
{$IFDEF LINUX}
{$linklib c}
{$linklib m}
{$linklib stdc++}
{$linklib gcc_s}
{$ENDIF}
{$IFDEF DARWIN}
{$linklib c++}
{$ENDIF}
{$endif}

{ ---------------------------------------------------------------------------
  TPiperPhonemizeResult
  --------------------------------------------------------------------------- }

constructor TPiperPhonemizeResult.Create(AHandle: Pointer);
begin
  inherited Create;
  FHandle := AHandle;
end;

destructor TPiperPhonemizeResult.Destroy;
begin
  if FHandle <> nil then
  begin
    PiperPhonemizeDestroyResult_c(FHandle);
    FHandle := nil;
  end;
  inherited Destroy;
end;

function TPiperPhonemizeResult.GetNumSentences: Integer;
begin
  Result := PiperPhonemizeResultGetNumSentences_c(FHandle);
end;

function TPiperPhonemizeResult.GetNumPhonemes(SentenceId: Integer): Integer;
begin
  Result := PiperPhonemizeResultGetNumPhonemes_c(FHandle, SentenceId);
end;

function TPiperPhonemizeResult.GetPhonemes(SentenceId: Integer): TPhonemeArray;
var
  NumPhonemes: Integer;
  PhonemesPtr: pcuint32;
  I: Integer;
begin
  Result := nil;
  NumPhonemes := GetNumPhonemes(SentenceId);
  if NumPhonemes <= 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  PhonemesPtr := PiperPhonemizeResultGetPhonemes_c(FHandle, SentenceId);
  if PhonemesPtr = nil then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Result, NumPhonemes);
  for I := 0 to NumPhonemes - 1 do
    Result[I] := PhonemesPtr[I];
end;

{ ---------------------------------------------------------------------------
  Public functions
  --------------------------------------------------------------------------- }

function PiperPhonemizeGetVersionStr: AnsiString;
begin
  Result := PiperPhonemizeGetVersionStr_c;
end;

function PiperPhonemizeInitialize(const DataDir: AnsiString): Integer;
begin
  Result := PiperPhonemizeInitialize_c(PAnsiChar(DataDir));
end;

function PiperPhonemizeText(const Text: AnsiString; const Voice: AnsiString): TPiperPhonemizeResult;
var
  Handle: PPiperPhonemizeResult;
begin
  Handle := PiperPhonemizeText_c(PAnsiChar(Text), PAnsiChar(Voice));
  if Handle = nil then
    Result := nil
  else
    Result := TPiperPhonemizeResult.Create(Handle);
end;

end.
