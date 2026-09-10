// Small, deterministic-shape generators for use from QML JavaScript.
// The generated banking identifiers are fictional and are not assertions about
// real bank accounts or reserved bank identifiers.

var countries = [
    { code: "BE", name: "Belgium" },
    { code: "NL", name: "Netherlands" },
    { code: "DE", name: "Germany" },
    { code: "FR", name: "France" }
];

var _dayMilliseconds = 24 * 60 * 60 * 1000;

function _pad(value, length) {
    var result = String(value);
    while (result.length < length) {
        result = "0" + result;
    }
    return result;
}

function _randomInt(maxExclusive) {
    return Math.floor(Math.random() * maxExclusive);
}

function _randomDigits(length) {
    var result = "";
    var i;
    for (i = 0; i < length; i += 1) {
        result += String(_randomInt(10));
    }
    return result;
}

function generateEmail() {
    var raw = "user" + _randomDigits(12) + "@example.com";
    return { raw: raw, formatted: raw };
}

function _dateParts(date) {
    return {
        year: date.getUTCFullYear(),
        month: date.getUTCMonth() + 1,
        day: date.getUTCDate()
    };
}

function _dateString(date) {
    var parts = _dateParts(date);
    return _pad(parts.year, 4) + "-" + _pad(parts.month, 2) + "-" + _pad(parts.day, 2);
}

function _parseBirthDate(value) {
    if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
        throw new TypeError("birthDate must be a YYYY-MM-DD string");
    }

    var year = Number(value.slice(0, 4));
    var month = Number(value.slice(5, 7));
    var day = Number(value.slice(8, 10));
    var date = new Date(Date.UTC(year, month - 1, day));
    if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) {
        throw new RangeError("birthDate is not a valid calendar date");
    }

    var today = new Date();
    var todayDate = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()));
    var earliest = Date.UTC(1940, 0, 1);
    if (date.getTime() < earliest || date.getTime() > todayDate.getTime()) {
        throw new RangeError("birthDate must be between 1940-01-01 and today");
    }
    return date;
}

function _randomBirthDate() {
    var now = new Date();
    var today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    var earliest = new Date(Date.UTC(1940, 0, 1));
    var dayCount = Math.floor((today.getTime() - earliest.getTime()) / _dayMilliseconds);
    return new Date(earliest.getTime() + _randomInt(dayCount + 1) * _dayMilliseconds);
}

function _inssChecksum(parts, serial) {
    var yyymmddSerial = _pad(parts.year % 100, 2) + _pad(parts.month, 2) + _pad(parts.day, 2) + _pad(serial, 3);
    var checksumInput = (parts.year >= 2000 ? "2" : "") + yyymmddSerial;
    return 97 - (Number(checksumInput) % 97);
}

function generateInss(options) {
    if (options === undefined) {
        options = {};
    }
    if (options === null || typeof options !== "object" || Array.isArray(options)) {
        throw new TypeError("options must be an object");
    }

    var optionKeys = Object.keys(options);
    var i;
    for (i = 0; i < optionKeys.length; i += 1) {
        if (optionKeys[i] !== "birthDate" && optionKeys[i] !== "sex") {
            throw new TypeError("unsupported generateInss option: " + optionKeys[i]);
        }
    }

    var sex = options.sex === undefined ? "random" : options.sex;
    if (sex !== "male" && sex !== "female" && sex !== "random") {
        throw new TypeError("sex must be male, female, or random");
    }
    if (options.birthDate !== undefined && typeof options.birthDate !== "string") {
        throw new TypeError("birthDate must be a YYYY-MM-DD string");
    }

    var date = options.birthDate === undefined ? _randomBirthDate() : _parseBirthDate(options.birthDate);
    if (sex === "random") {
        sex = Math.random() < 0.5 ? "male" : "female";
    }
    var serial = sex === "male" ? 1 + _randomInt(499) * 2 : 2 + _randomInt(499) * 2;
    var parts = _dateParts(date);
    var datePart = _pad(parts.year % 100, 2) + _pad(parts.month, 2) + _pad(parts.day, 2);
    var raw = datePart + _pad(serial, 3) + _pad(_inssChecksum(parts, serial), 2);

    return {
        raw: raw,
        formatted: raw.slice(0, 2) + "." + raw.slice(2, 4) + "." + raw.slice(4, 6) + "-" + raw.slice(6, 9) + "-" + raw.slice(9),
        birthDate: _dateString(date),
        sex: sex
    };
}

function generateBsn() {
    // Rejection sampling keeps valid prefixes equally likely. Bound retries so
    // a broken random source cannot block the QML event loop indefinitely.
    for (var attempt = 0; attempt < 100; attempt += 1) {
        var prefix = _randomDigits(8);
        var sum = 0;
        for (var i = 0; i < prefix.length; i += 1) {
            sum += Number(prefix.charAt(i)) * (9 - i);
        }
        var checkDigit = sum % 11;
        if (checkDigit === 10 || prefix === "00000000") continue;

        var raw = prefix + String(checkDigit);
        return { raw: raw, formatted: raw };
    }
    throw new Error("Unable to generate a BSN after 100 attempts");
}

function _mod97(value) {
    var remainder = 0;
    var i;
    for (i = 0; i < value.length; i += 1) {
        remainder = (remainder * 10 + Number(value.charAt(i))) % 97;
    }
    return remainder;
}

function _lettersToDigits(value) {
    var result = "";
    var i;
    for (i = 0; i < value.length; i += 1) {
        var character = value.charAt(i);
        if (/[A-Z]/.test(character)) {
            result += String(character.charCodeAt(0) - 55);
        } else {
            result += character;
        }
    }
    return result;
}

function _ibanCheckDigits(countryCode, bban) {
    var rearranged = bban + _lettersToDigits(countryCode) + "00";
    return _pad(98 - _mod97(_lettersToDigits(rearranged)), 2);
}

function _formatIban(raw) {
    var groups = [];
    var i;
    for (i = 0; i < raw.length; i += 4) {
        groups.push(raw.slice(i, i + 4));
    }
    return groups.join(" ");
}

function _countryCode(code) {
    if (typeof code !== "string" || !/^[A-Za-z]{2}$/.test(code)) {
        throw new TypeError("country code must be a two-letter code");
    }
    var normalized = code.toUpperCase();
    var i;
    for (i = 0; i < countries.length; i += 1) {
        if (countries[i].code === normalized) {
            return normalized;
        }
    }
    throw new RangeError("unsupported country code: " + code);
}

function _makeBban(code) {
    var bank;
    var branch;
    var account;
    var domesticCheck;
    if (code === "BE") {
        bank = _randomDigits(3);
        account = _randomDigits(7);
        // A zero remainder is written as 97, never 00, in Belgian BBANs.
        domesticCheck = (Number(bank + account) % 97) || 97;
        return bank + account + _pad(domesticCheck, 2);
    }
    if (code === "NL") {
        return "TEST" + _randomDigits(10);
    }
    if (code === "DE") {
        return _randomDigits(18);
    }

    // France: use a numeric account so the RIB formula is straightforward.
    bank = _randomDigits(5);
    branch = _randomDigits(5);
    account = _randomDigits(11);
    domesticCheck = 97 - ((89 * Number(bank) + 15 * Number(branch) + 3 * Number(account)) % 97);
    return bank + branch + account + _pad(domesticCheck, 2);
}

function generateIban(code) {
    var countryCode = _countryCode(code);
    var bban = _makeBban(countryCode);
    var raw = countryCode + _ibanCheckDigits(countryCode, bban) + bban;
    return {
        raw: raw,
        formatted: _formatIban(raw),
        country: countryCode
    };
}
