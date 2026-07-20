{ example.pas }
{ Example: Phonemize text using piper-phonemize Pascal API }
{
  Usage:
    ./example /path/to/espeak-ng-data
}
program example;

{$mode objfpc}{$H+}

uses
  Classes,
  SysUtils,
  piper_phonemize;

var
  DataDir: AnsiString;
  SampleRate: Integer;
  Text: AnsiString;
  Voice: AnsiString;
  Result: TPiperPhonemizeResult;
  I, J: Integer;
  Phonemes: TPhonemeArray;
begin
  if ParamCount < 1 then
  begin
    WriteLn('Usage: ', ParamStr(0), ' <espeak-ng-data-dir>');
    Halt(1);
  end;

  DataDir := ParamStr(1);
  WriteLn('Version: ', PiperPhonemizeGetVersionStr);
  WriteLn('Data dir: ', DataDir);

  { Initialize espeak-ng }
  SampleRate := PiperPhonemizeInitialize(DataDir);
  WriteLn('Sample rate: ', SampleRate);

  if SampleRate < 0 then
  begin
    WriteLn('Error: Failed to initialize espeak-ng');
    Halt(1);
  end;

  { Phonemize some text }
  Text := 'Hello world. This is a test.';
  Voice := 'en-us';

  WriteLn('');
  WriteLn('Input: ', Text);
  WriteLn('Voice: ', Voice);

  Result := PiperPhonemizeText(Text, Voice);
  if Result = nil then
  begin
    WriteLn('Error: Phonemization failed');
    Halt(1);
  end;

  WriteLn('Sentences: ', Result.GetNumSentences);

  for I := 0 to Result.GetNumSentences - 1 do
  begin
    Phonemes := Result.GetPhonemes(I);
    Write('  Sentence ', I + 1, ': ');
    for J := 0 to Length(Phonemes) - 1 do
    begin
      if J > 0 then
        Write(' ');
      Write(IntToHex(Phonemes[J], 4));
    end;
    WriteLn;
  end;

  { Clean up }
  FreeAndNil(Result);

  WriteLn('');
  WriteLn('Done!');
end.
