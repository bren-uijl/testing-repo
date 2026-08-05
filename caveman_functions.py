def add(a, b):
    return a + b


def multiply(a, b):
    return a * b


def is_even(n):
    return n % 2 == 0


def reverse_string(s):
    return s[::-1]


def count_vowels(s):
    count = 0
    for c in s:
        if c in "aeiouAEIOU":
            count += 1
    return count


if __name__ == "__main__":
    assert add(2, 3) == 5
    assert multiply(4, 5) == 20
    assert is_even(10) is True
    assert is_even(7) is False
    assert reverse_string("caveman") == "namevac"
    assert count_vowels("caveman") == 3
    assert count_vowels("sky") == 0
    print("All caveman tests passed!")