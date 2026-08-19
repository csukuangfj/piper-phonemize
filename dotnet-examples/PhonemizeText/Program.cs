// Copyright (c) 2026  Xiaomi Corporation

using System;
using System.IO;
using PiperPhonemize;

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine($"piper-phonemize version: {PiperPhonemizeApi.GetVersionStr()}");

        // Find espeak-ng-data directory
        string dataDir = FindEspeakNgData();
        if (dataDir == null)
        {
            Console.Error.WriteLine("ERROR: espeak-ng-data not found.");
            Environment.Exit(1);
        }

        Console.WriteLine($"espeak-ng-data: {dataDir}");

        int sampleRate = PiperPhonemizeApi.Initialize(dataDir);
        Console.WriteLine($"Sample rate: {sampleRate}");

        string text = "Hello world. This is a test. The weather is beautiful today.";
        if (args.Length > 0)
            text = string.Join(" ", args);

        Console.WriteLine($"\nInput: \"{text}\"");

        using (var result = PiperPhonemizeApi.Text(text))
        {
            if (result != null)
            {
                Console.WriteLine($"Sentences: {result.NumSentences}");
                for (int i = 0; i < result.NumSentences; i++)
                {
                    string ipa = result.GetPhonemesAsString(i);
                    Console.WriteLine($"  Sentence {i + 1}: {ipa}");
                }
            }
            else
            {
                Console.WriteLine("Phonemization failed.");
            }
        }
    }

    static string FindEspeakNgData()
    {
        // Check relative to executable
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;

        string[] candidates = new[]
        {
            Path.Combine(exeDir, "espeak-ng-data"),
            Path.Combine(exeDir, "..", "espeak-ng-data"),
            Path.Combine(exeDir, "..", "..", "..", "espeak-ng-data"),
            "espeak-ng-data",
        };

        foreach (var candidate in candidates)
        {
            if (Directory.Exists(candidate) && File.Exists(Path.Combine(candidate, "phontab")))
                return Path.GetFullPath(candidate);
        }

        return null;
    }
}
