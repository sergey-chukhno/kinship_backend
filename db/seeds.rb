require "open-uri"
require "csv"
ActionMailer::Base.perform_deliveries = false

puts "Starting seeds..."

puts "Do you want to generate all the school from the API ? (y/n)"
answer = gets.chomp
if answer == "y"
  puts "Do you want to upload all the schools ? (approx 70k records) - If no, only the first thousand schools will be uploaded (y/n)"
  full_api = gets.chomp
end

if Rails.env.production?
  puts "Welcome to production...."

  print "Creating users..."
  User.create!(
    email: "charlie.bertrand@drakkar.io",
    first_name: "Charlie",
    last_name: "Bertrand",
    birthday: "1989-08-08",
    role: "tutor",
    job: "Developpeur",
    password: "Password@",
    role_additional_information: "Ruby on rails / react native",
    accept_privacy_policy: true,
    admin: true
  )

  User.create!(
    email: "elowan.audouin@drakkar.io",
    first_name: "Elowan",
    last_name: "Audouin",
    birthday: "23-11-2002",
    role: "tutor",
    job: "Developpeur",
    password: "Password@",
    role_additional_information: "Ruby on rails / react native",
    accept_privacy_policy: true,
    admin: true
  )
  User.all.each(&:confirm)
  puts "Done !"

  print "Creating tags..."
  Tag.create!([
    {
      name: "Santé"
    },
    {
      name: "Citoyen"
    },
    {
      name: "EAC"
    },
    {
      name: "Créativité"
    },
    {
      name: "Avenir"
    },
    {
      name: "Autre"
    }
  ])
  puts "done !"

  puts "Creating Schools from API..."
  # * DL THE DATA SET IN CSV
  # https://data.education.gouv.fr/explore/dataset/fr-en-annuaire-education/export/
  filepath = "db/fr-en-annuaire-education.csv"
  CSV.foreach(filepath, headers: true, col_sep: ";") do |row|
    school_type = case row["Type_etablissement"]
    when "Ecole"
      "primaire"
    when "Collège"
      "college"
    when "Lycée"
      "lycee"
    when "EREA"
      "erea"
    when "Médico-social"
      "medico_social"
    when "Service Administratif"
      "service_administratif"
    when "Information et orientation"
      "information_et_orientation"
    else
      "autre"
    end
    School.find_or_create_by!(
      name: row["Nom_etablissement"],
      zip_code: row["Code postal"],
      school_type: school_type,
      city: row["Nom_commune"]
    )
    puts "  #{row["Nom_etablissement"]} (#{school_type} - #{row["Code postal"]}) créé !"
  end
  puts "#{School.all.count} schools created !"
else
  print "Cleaning database..."
  DatabaseCleaner.clean_with(:truncation)
  puts " ✅"

  print "Creating Schools Test..."
  lycee_test = School.find_or_create_by(
    name: "Lycée du test",
    zip_code: "75017",
    school_type: "lycee",
    city: "Paris"
  )
  college_test = School.find_or_create_by(
    name: "Collège du test",
    zip_code: "44000",
    school_type: "college",
    city: "Nantes"
  )
  ecole_test = School.find_or_create_by(
    name: "Ecole du test",
    zip_code: "49000",
    school_type: "primaire",
    city: "Angers"
  )
  puts " ✅"

  print "Creating School Levels Test..."
  SchoolLevel.create!([
    {
      level: :sixieme,
      name: "A",
      school: college_test
    },
    {
      level: :cinquieme,
      name: "B",
      school: college_test
    },
    {
      level: :quatrieme,
      name: "C",
      school: college_test
    },
    {
      level: :troisieme,
      name: "D",
      school: college_test
    },
    {
      level: :seconde,
      name: "E",
      school: lycee_test
    },
    {
      level: :premiere,
      name: "F",
      school: lycee_test
    },
    {
      level: :terminale,
      name: "G",
      school: lycee_test
    },
    {
      level: :petite_section,
      name: "1",
      school: ecole_test
    },
    {
      level: :moyenne_section,
      name: "2",
      school: ecole_test
    },
    {
      level: :grande_section,
      name: "3",
      school: ecole_test
    },
    {
      level: :cp,
      name: "4",
      school: ecole_test
    },
    {
      level: :ce1,
      name: "5",
      school: ecole_test
    },
    {
      level: :ce2,
      name: "6",
      school: ecole_test
    },
    {
      level: :cm1,
      name: "7",
      school: ecole_test
    },
    {
      level: :cm2,
      name: "8",
      school: ecole_test
    }
  ])
  puts " ✅"

  if answer == "y"
    puts "Creating Schools from API..."
    # * DL THE DATA SET IN CSV
    # https://data.education.gouv.fr/explore/dataset/fr-en-annuaire-education/export/
    filepath = "db/fr-en-annuaire-education.csv"
    index = 0
    CSV.foreach(filepath, headers: true, col_sep: ";") do |row|
      school_type = case row["Type_etablissement"]
      when "Ecole"
        "primaire"
      when "Collège"
        "college"
      when "Lycée"
        "lycee"
      when "EREA"
        "erea"
      when "Médico-social"
        "medico_social"
      when "Service Administratif"
        "service_administratif"
      when "Information et orientation"
        "information_et_orientation"
      else
        "autre"
      end
      School.find_or_create_by!(
        name: row["Nom_etablissement"],
        zip_code: row["Code postal"],
        school_type: school_type,
        city: row["Nom_commune"]
      )
      puts "  #{row["Nom_etablissement"]} (#{school_type} - #{row["Code postal"]}) créé !"
      index += 1
      break if index == 1000 && full_api != "y"
    end
    puts "Creating Schools from API... ✅"
  end

  print "Creating skills..."
  Skill.create!([
    {
      name: "Multilangues",
      official: true
    },
    {
      name: "Fabrication d'objets",
      official: true
    },
    {
      name: "Théatre & Communication",
      official: true
    },
    {
      name: "Journalisme & Média",
      official: true
    },
    {
      name: "Sports & initiation",
      official: true
    },
    {
      name: "Informatique & Numérique",
      official: true
    },
    {
      name: "Gestion & Formation",
      official: true
    },
    {
      name: "Danse & Musique",
      official: true
    },
    {
      name: "Créativité",
      official: true
    },
    {
      name: "Bricolage & Jardinage",
      official: true
    },
    {
      name: "Arts & Culture",
      official: true
    },
    {
      name: "Cuisine et ses techniques",
      official: true
    },
    {
      name: "Audiovisuel & Cinéma",
      official: true
    }
  ])
  puts " ✅"

  print "Creating sub skills..."
  SubSkill.create!([
    {
      skill: Skill.find_by(name: "Audiovisuel & Cinéma"),
      name: "Technique de Réalisation"
    },
    {
      skill: Skill.find_by(name: "Audiovisuel & Cinéma"),
      name: "Photo"
    },
    {
      skill: Skill.find_by(name: "Audiovisuel & Cinéma"),
      name: "Vidéo"
    },
    {
      skill: Skill.find_by(name: "Audiovisuel & Cinéma"),
      name: "Montage Vidéo"
    },
    {
      skill: Skill.find_by(name: "Arts & Culture"),
      name: "Décors"
    },
    {
      skill: Skill.find_by(name: "Arts & Culture"),
      name: "Déssin"
    },
    {
      skill: Skill.find_by(name: "Arts & Culture"),
      name: "Peinture"
    },
    {
      skill: Skill.find_by(name: "Bricolage & Jardinage"),
      name: "Création diverse"
    },
    {
      skill: Skill.find_by(name: "Bricolage & Jardinage"),
      name: "Plomberie"
    },
    {
      skill: Skill.find_by(name: "Bricolage & Jardinage"),
      name: "Électricité"
    },
    {
      skill: Skill.find_by(name: "Bricolage & Jardinage"),
      name: "Menuiserie"
    },
    {
      skill: Skill.find_by(name: "Créativité"),
      name: "Atelier d'idéation"
    },
    {
      skill: Skill.find_by(name: "Créativité"),
      name: "Poterie"
    },
    {
      skill: Skill.find_by(name: "Créativité"),
      name: "Création diverse"
    },
    {
      skill: Skill.find_by(name: "Créativité"),
      name: "Couture"
    },
    {
      skill: Skill.find_by(name: "Danse & Musique"),
      name: "Piano"
    },
    {
      skill: Skill.find_by(name: "Danse & Musique"),
      name: "Rock"
    },
    {
      skill: Skill.find_by(name: "Danse & Musique"),
      name: "Salsa"
    },
    {
      skill: Skill.find_by(name: "Danse & Musique"),
      name: "Technique de chant"
    },
    {
      skill: Skill.find_by(name: "Gestion & Formation"),
      name: "Gestion de projet"
    },
    {
      skill: Skill.find_by(name: "Gestion & Formation"),
      name: "Comptabilité"
    },
    {
      skill: Skill.find_by(name: "Informatique & Numérique"),
      name: "Initiation"
    },
    {
      skill: Skill.find_by(name: "Informatique & Numérique"),
      name: "Utilisation de logiciel"
    },
    {
      skill: Skill.find_by(name: "Informatique & Numérique"),
      name: "Design"
    },
    {
      skill: Skill.find_by(name: "Informatique & Numérique"),
      name: "Développeur"
    },
    {
      skill: Skill.find_by(name: "Journalisme & Média"),
      name: "Reportage vidéo"
    },
    {
      skill: Skill.find_by(name: "Journalisme & Média"),
      name: "Rédaction d'article"
    },
    {
      skill: Skill.find_by(name: "Journalisme & Média"),
      name: "Prise de parole en public"
    },
    {
      skill: Skill.find_by(name: "Théatre & Communication"),
      name: "Atelier d'improvisation"
    },
    {
      skill: Skill.find_by(name: "Théatre & Communication"),
      name: "Décors"
    },
    {
      skill: Skill.find_by(name: "Théatre & Communication"),
      name: "Prise de parole en public"
    },
    {
      skill: Skill.find_by(name: "Multilangues"),
      name: "Parler et traduire une langue à l'écrit"
    },
    {
      skill: Skill.find_by(name: "Multilangues"),
      name: "Parler et traduire une langue à l'oral"
    }
  ])
  puts " ✅"

  print "Creating CompanyType"
  CompanyType.create!([
    {
      name: "Entreprise"
    },
    {
      name: "Association"
    },
    {
      name: "Collectivité"
    }
  ])
  puts " ✅"

  print "Creating Companies..."
  5.times do
    FactoryBot.create(:company, :confirmed, company_type: CompanyType.all.sample)
  end
  puts " ✅"

  print "Creating Users..."
  User.create!(
    first_name: "Admin",
    last_name: "Admin",
    email: "admin@drakkar.io",
    password: "password",
    birthday: "1989-08-08",
    role: "tutor",
    job: "Developpeur",
    accept_privacy_policy: true,
    role_additional_information: "Ruby on rails / react native",
    admin: true,
    super_admin: true
  )
  User.create!(
    first_name: "Admin",
    last_name: "Teacher",
    email: "admin@ac-nantes.fr",
    password: "password",
    birthday: "1989-08-08",
    role: "teacher",
    job: "Developpeur",
    accept_privacy_policy: true,
    role_additional_information: "Ruby on rails / react native",
    admin: true,
    super_admin: true
  )
  User.create!(
    first_name: "Sergey",
    last_name: "Tutor",
    email: "sergey.chukhno@laplateforme.fr",
    password: "password",
    birthday: "1989-08-08",
    role: "tutor",
    job: "Developpeur",
    accept_privacy_policy: true,
    role_additional_information: "Ruby on rails / react native",
    admin: true,
    super_admin: true
  )
  10.times do
    User.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      password: Faker::Internet.password,
      birthday: Faker::Date.birthday(min_age: 18, max_age: 65),
      role: "tutor",
      job: Faker::Job.title,
      accept_privacy_policy: true,
      role_additional_information: Faker::Lorem.paragraph(sentence_count: 2),
      skill_additional_information: Faker::Lorem.paragraph(sentence_count: 2),
      propose_workshop: [true, false].sample,
      take_trainee: [true, false].sample,
      show_my_skills: [true, false].sample,
      expend_skill_to_school: [true, false].sample,
      certify: [true, false].sample
    )
  end
  10.times do
    User.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email(domain: "ac-nantes.fr"),
      password: Faker::Internet.password,
      birthday: Faker::Date.birthday(min_age: 18, max_age: 65),
      role: "teacher",
      job: Faker::Job.title,
      accept_privacy_policy: true,
      accept_marketing: [true, false].sample,
      role_additional_information: Faker::Lorem.paragraph(sentence_count: 2),
      show_my_skills: [true, false].sample,
      skill_additional_information: Faker::Lorem.paragraph(sentence_count: 2),
      expend_skill_to_school: [true, false].sample,
      certify: [true, false].sample
    )
  end
  User.all.each(&:confirm)
  puts " ✅"

  print "Creating User Companies..."
  User.where.not(role: "teacher").each do |user|
    FactoryBot.create(:user_company, user: user, company: Company.all.sample)
  end
  puts " ✅"

  print "Creating User Schools..."
  User.all.each do |user|
    UserSchool.create!(
      user: user,
      school: [lycee_test, college_test, ecole_test].sample,
      admin: user.admin
    )
  end
  puts " ✅"

  print "Creating User School Levels..."
  User.where(role: "tutor").each do |user|
    UserSchoolLevel.create!(
      user: user,
      school_level: user.schools.sample.school_levels.sample
    )
  end
  puts " ✅"

  print "Creating Users Availability..."
  User.where(role: "tutor").each do |user|
    Availability.find_by(user: user).update(
      monday: [true, false].sample,
      tuesday: [true, false].sample,
      wednesday: [true, false].sample,
      thursday: [true, false].sample,
      friday: [true, false].sample,
      other: [true, false].sample
    )
  end
  puts " ✅"

  print "Creating User Skills..."
  User.where(expend_skill_to_school: true).each do |user|
    skills = Skill.all.sample(3)
    3.times do
      UserSkill.create!(
        user: user,
        skill: skills.pop
      )
    end
  end
  puts " ✅"

  # print "Creating User Sub Skills..."
  #   User.where(expend_skill_to_school: true).each do |user|
  #     UserSubSkill.create!(
  #       user: user,
  #       sub_skill: user.skills.sample.sub_skills.sample
  #     )
  #   end
  # puts " ✅"

  print "Creating Tags..."
  Tag.create!([
    {
      name: "Santé"
    },
    {
      name: "Citoyen"
    },
    {
      name: "EAC"
    },
    {
      name: "Créativité"
    },
    {
      name: "Avenir"
    },
    {
      name: "Autre"
    }
  ])
  puts " ✅"

  print "Creating Projects..."
  puts "Do you want to upload images ? (y/n)"
  image = gets.chomp
  7.times do
    Project.create!(
      title: Faker::Lorem.sentence(word_count: 10),
      description: Faker::Lorem.paragraph(sentence_count: 10),
      owner: User.teacher.sample,
      project_school_levels: [ProjectSchoolLevel.new(school_level: SchoolLevel.all.sample)],
      start_date: Faker::Date.between(from: 1.year.ago, to: Date.today),
      end_date: Faker::Date.between(from: Date.today, to: 1.year.from_now),
      status: Project.statuses.keys.sample,
      participants_number: rand(1..100),
      time_spent: rand(1..35)
    )

    if image == "y"
      Project.last.main_picture.attach(io: URI.parse(Faker::LoremFlickr.image(size: "300x300")).open, filename: "main_picture.jpg", content_type: "image/jpg")
      3.times do
        Project.last.pictures.attach(io: URI.parse(Faker::LoremFlickr.image(size: "300x300")).open, filename: "picture1.jpg", content_type: "image/jpg")
      end
    end
  end
  3.times do
    Project.create!(
      title: Faker::Lorem.sentence(word_count: 10),
      description: Faker::Lorem.paragraph(sentence_count: 10),
      owner: User.first,
      start_date: Faker::Date.between(from: 1.year.ago, to: Date.today),
      end_date: Faker::Date.between(from: Date.today, to: 1.year.from_now),
      status: Project.statuses.keys.sample,
      participants_number: rand(1..100),
      time_spent: rand(1..35)
    )
    if image == "y"
      Project.last.main_picture.attach(io: URI.parse(Faker::LoremFlickr.image(size: "300x300")).open, filename: "main_picture.jpg", content_type: "image/jpg")
      3.times do
        Project.last.pictures.attach(io: URI.parse(Faker::LoremFlickr.image(size: "300x300")).open, filename: "picture1.jpg", content_type: "image/jpg")
      end
    end
  end
  puts " ✅"

  print "Creating Project Tags..."
  Project.all.each do |project|
    tags = Tag.all.sample(3)
    3.times do
      ProjectTag.create!(
        project: project,
        tag: tags.pop
      )
    end
  end
  puts " ✅"

  print "Creating Project Skills..."
  Project.all.each do |project|
    skills = Skill.all.sample(3)
    3.times do
      ProjectSkill.create!(
        project: project,
        skill: skills.pop
      )
    end
  end
  puts " ✅"

  print "Creating Project School Levels..."
  Project.last(3).each do |project|
    project.school_levels.destroy_all
  end
  puts " ✅"

  print "Creating Project Link..."
  Project.all.each do |project|
    3.times do
      Link.create!(
        project: project,
        name: Faker::Lorem.sentence,
        url: Faker::Internet.url(scheme: "https")
      )
    end
  end
  puts " ✅"

  print "Creating Project Keyword..."
  Project.all.each do |project|
    3.times do
      Keyword.create!(
        project: project,
        name: Faker::Lorem.sentence
      )
    end
  end
  puts " ✅"

  print "Creating Team..."
  Project.all.each do |project|
    rand(1..3).times do
      Team.create!(
        project: project,
        title: Faker::Lorem.sentence(word_count: 3),
        description: Faker::Lorem.paragraph(sentence_count: 2)
      )
    end
  end
  puts " ✅"

  print "Creating Team Member..."
  Team.all.each do |team|
    users = User.all.sample(3)
    rand(1..3).times do
      TeamMember.create!(
        team: team,
        user: users.pop
      )
    end
  end
  puts " ✅"
end

puts "Seeds over, here is a dragon"

puts "                                                ██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████
░░██████                                        ██████▒▒▒▒▒▒▒▒░░░░░░░░░░░░████
░░██▒▒████                                    ████▒▒▒▒▒▒░░░░░░  ░░  ░░  ████
░░████▒▒████████                            ████▒▒▒▒░░  ░░  ░░░░░░░░░░░░██
    ██▒▒▒▒▒▒▒▒████                        ████▒▒▒▒░░░░░░  ░░░░  ░░  ░░░░██
    ██▒▒▒▒██▒▒████████████              ████▒▒▒▒░░  ░░  ░░  ░░░░░░░░░░  ██
    ████▒▒▒▒██▒▒▒▒██████              ████▒▒▒▒  ░░░░░░░░░░░░░░░░  ░░░░░░██
      ████▒▒██▒▒████████              ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████
        ████▒▒▒▒██████████████          ██░░▒▒▒▒░░░░  ░░░░░░  ░░  ████████
        ██████▒▒████▒▒██████            ██░░▒▒▒▒▒▒▒▒  ░░  ░░░░░░████
            ████████▒▒████            ████░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒░░  ██
          ██████████▒▒████            ██  ░░▒▒▒▒  ░░░░░░░░▒▒▒▒  ██
          ██████████▒▒████        ████░░░░▒▒▒▒░░░░░░  ░░░░    ▒▒██
              ██▒▒██████████████████▒▒▒▒▒▒▒▒  ░░░░  ░░░░  ░░  ▒▒████
              ██▒▒██████████████▒▒████▒▒▒▒▒▒░░░░░░░░░░░░░░░░  ▒▒▒▒████    ██
              ██████▒▒▒▒▒▒▒▒████████████░░  ░░░░░░  ░░░░░░░░████████████  ████
                  ██████▒▒▒▒▒▒▒▒██████████████████░░░░░░░░██████        ████████
                      ██████▒▒▒▒████████████████░░░░░░  ░░██            ██▒▒▒▒██
                          ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████████  ██          ████▒▒██▒▒██
                      ██████▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒██████████████          ████▒▒██▒▒██
      ██████████████████░░▒▒▒▒░░░░░░░░  ▒▒▒▒▒▒▒▒▒▒██████████████      ████████████
    ██▒▒██████░░    ░░░░▒▒▒▒  ░░░░    ░░░░░░  ▒▒▒▒▒▒▒▒██████████████      ████
    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░  ██████▒▒▒▒▒▒▒▒████████        ████
    ██▒▒  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ░░░░░░░░░░░░████▒▒████▒▒▒▒▒▒▒▒▒▒████████  ██████
    ██▒▒░░░░▒▒  ▒▒▒▒░░░░  ░░░░░░░░  ░░░░░░████▒▒██████▒▒▒▒▒▒▒▒▒▒████████████
    ██▒▒░░  ▒▒  ▒▒░░  ░░░░    ░░  ░░░░  ░░██████████████▒▒▒▒▒▒▒▒▒▒████████
    ██▒▒  ░░▒▒░░  ▒▒▒▒▒▒▒▒  ░░░░░░░░  ░░  ██          ██████▒▒▒▒▒▒▒▒████
    ██▒▒▒▒░░▒▒░░░░    ▒▒▒▒▒▒▒▒░░░░░░░░░░░░██          ████████▒▒▒▒▒▒▒▒████
    ██▒▒▒▒░░░░▒▒▒▒  ░░░░  ░░▒▒▒▒▒▒████████████      ████████████▒▒▒▒▒▒██████
    ██▒▒▒▒░░░░▒▒▒▒  ░░░░░░░░░░░░██        ████    ██████      ████▒▒▒▒████████
    ██▒▒▒▒░░░░░░▒▒▒▒░░░░  ░░  ░░██              ████            ██▒▒▒▒██
      ██▒▒▒▒░░  ▒▒▒▒▒▒░░░░░░████████          ██████            ██▒▒▒▒████
      ██▒▒▒▒  ░░  ░░▒▒▒▒▒▒██████████          ████              ██▒▒▒▒██████
      ████▒▒▒▒░░  ░░░░░░░░██  ░░  ░░        ██████              ██▒▒▒▒████████
        ████▒▒░░░░░░░░░░░░██                ██▒▒████          ████▒▒▒▒██
          ████▒▒▒▒░░░░░░  ██                ████▒▒████        ██▒▒▒▒██████
              ██████▒▒▒▒▒▒██████                ██▒▒▒▒████████▒▒▒▒████████
                  ██████████████                ██████████▒▒▒▒██████
                                                      ██████████          "
