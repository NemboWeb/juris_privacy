require_relative 'test_helper'

# TestObscurer
class TestObscurer < Minitest::Test
  def setup
    whitelisted_words = %w(arena bicicletta come non)
    whitelist = JurisPrivacy::Whitelist.new whitelisted_words
    blacklisted_words = %w(marco paolo luca)
    blacklist = JurisPrivacy::Blacklist.new blacklisted_words
    @obscurer = JurisPrivacy::Obscurer.new whitelist, blacklist
  end

  # Don't censor whitelisted words
  def test_whitelist
    text = 'ciao io mi chiamo Lattuga Bicicletta, Come Non mi riconosci?'
    expected_censored_data = { 'L.Bicicletta' => 'Lattuga Bicicletta' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  # Censor blacklisted words
  def test_blacklist
    text = 'ciao io mi chiamo luca paoli'
    expected_censored_data = { 'L.' => 'luca' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  # Censor words after and before blacklisted words
  # if they starts with capital letter
  def test_blacklist_match
    text = 'ciao io mi chiamo luca Paoli, il mio amico Valli marco'
    expected_censored_data = { 'L.P.' => 'luca Paoli',
                               'V.M.' => 'Valli marco' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  # Blacklist has priority over Whitelist
  def test_black_and_white_priority
    text = 'ciao io mi chiamo Luca Bicicletta'
    expected_censored_data = { 'L.B.' => 'Luca Bicicletta' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  # Blacklist is updated with already matched full Names
  def test_update_blacklist
    text = 'ciao io mi chiamo Lorenzo Bargnani, il mio cognome è bargnani,'\
           'ops intendevo Bargnani'
    expected_censored_data = { 'L.B.' => 'Lorenzo Bargnani',
                               'B.' => 'bargnani',
                               'B.A.' => 'Bargnani' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  # Names with same initials and number of letters
  # are identified by trailing letters
  def test_name_collisions
    text = 'ciao io mi chiamo Luca Baffoni '\
           'e questa è la mia amica Lara Bassini'
    expected_censored_data = { 'L.B.' => 'Luca Baffoni',
                               'L.B.A.' => 'Lara Bassini' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  def test_name_with_two_chars_prefixes
    text = 'ciao io mi chiamo Maria De Filippi, il mio amico Marco D\'Ubaldo.'\
           'Sono presenti in aula Dell\'Utri Marcello e Di Girolamo Matteo'
    expected_censored_data = { 'M.D.F.' => 'Maria De Filippi',
                               'M.D.' => 'Marco D\'Ubaldo',
                               'D.M.' => 'Dell\'Utri Marcello',
                               'D.G.M.' => 'Di Girolamo Matteo' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  def test_name_with_common_prefixes
    text = 'ciao io mi chiamo Maria Degli Espositi,'\
           'il mio amico Michele Della Santina'
    expected_censored_data = { 'M.D.E.' => 'Maria Degli Espositi',
                               'M.D.S.' => 'Michele Della Santina' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  def test_multiple_name
    text = 'ciao io mi chiamo Maria Elisabetta Escobar,'\
           'il mio amico Franco Mauro Giulio Monti'
    expected_censored_data = { 'M.E.E.' => 'Maria Elisabetta Escobar',
                               'F.M.G.M.' => 'Franco Mauro Giulio Monti' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  def test_name_with_upcase_words
    text = 'Sono qui presenti Mauro BALLARINI, DE ANDRE\' Girolamo,'\
           'MATILDE Pertini, D\'AMICO Ilaria... non rileviamo però GUIDO FORTE'
    expected_censored_data = { 'M.B.' => 'Mauro BALLARINI',
                               'D.A.G.' => 'DE ANDRE\' Girolamo',
                               'M.P.' => 'MATILDE Pertini',
                               'D.I.' => 'D\'AMICO Ilaria' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  def test_tax_code
    text = 'ciao il mio codice fiscale è NGLLNZ92R30C357W'
    expected_censored_data = { 'N.' => 'NGLLNZ92R30C357W' }
    assert_equal expected_censored_data, @obscurer.inspect(text)
  end

  def test_obscure_text
    text = 'ciao io mi chiamo Michele Ferrucci, la mia amica invece '\
           'si chiama Michela Falcioni'
    expected_obscured_text = 'ciao io mi chiamo M.F., '\
                             'la mia amica invece si chiama M.F.A.'
    assert_equal expected_obscured_text, @obscurer.obscure_text(text)
  end
end
