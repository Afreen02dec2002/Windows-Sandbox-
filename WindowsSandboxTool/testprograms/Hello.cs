using System;

class Program
{
    static void Main()
    {
        Console.WriteLine("Hello World!");
        Console.Write("Enter your name: ");
        string name = Console.ReadLine();
        if (string.IsNullOrEmpty(name))
        {
            name = "World";
        }
        Console.WriteLine("Hello " + name + "!");
        Console.WriteLine("Press any key to exit...");
        Console.ReadKey();
    }
}