gem 'gherkin', '>=4.0.0'

require 'gherkin/parser'
require 'gherkin_lint/linter'
require 'gherkin_lint/linter/avoid_outline_for_single_example'
require 'gherkin_lint/linter/avoid_period'
require 'gherkin_lint/linter/avoid_scripting'
require 'gherkin_lint/linter/background_does_more_than_setup'
require 'gherkin_lint/linter/background_requires_multiple_scenarios'
require 'gherkin_lint/linter/bad_scenario_name'
require 'gherkin_lint/linter/be_declarative'
require 'gherkin_lint/linter/file_name_differs_feature_name'
require 'gherkin_lint/linter/invalid_file_name'
require 'gherkin_lint/linter/invalid_step_flow'
require 'gherkin_lint/linter/missing_example_name'
require 'gherkin_lint/linter/missing_feature_description'
require 'gherkin_lint/linter/missing_feature_name'
require 'gherkin_lint/linter/missing_scenario_name'
require 'gherkin_lint/linter/missing_test_action'
require 'gherkin_lint/linter/missing_verification'
require 'gherkin_lint/linter/required_tags'
require 'gherkin_lint/linter/same_tag_for_all_scenarios'
require 'gherkin_lint/linter/tag_used_multiple_times'
require 'gherkin_lint/linter/too_clumsy'
require 'gherkin_lint/linter/too_long_step'
require 'gherkin_lint/linter/too_many_different_tags'
require 'gherkin_lint/linter/too_many_steps'
require 'gherkin_lint/linter/too_many_tags'
require 'gherkin_lint/linter/unique_scenario_names'
require 'gherkin_lint/linter/unknown_variable'
require 'gherkin_lint/linter/unused_variable'
require 'gherkin_lint/linter/use_background'
require 'gherkin_lint/linter/use_outline'
require 'multi_json'
require 'set'

module GherkinLint
  # gherkin linter
  class GherkinLint
    LINTER = Linter.descendants

    def initialize
      @files = {}
      @linter = []
    end

    def enable_all
      disable []
    end

    def enable(enabled_linter)
      set_linter(enabled_linter)
    end

    def disable(disabled_linter)
      set_linter(LINTER.map { |linter| linter.new.name.split('::').last }, disabled_linter)
    end

    def set_linter(enabled_linter, disabled_linter = [])
      @linter = []
      enabled_linter = Set.new enabled_linter
      disabled_linter = Set.new disabled_linter
      LINTER.each do |linter|
        new_linter = linter.new
        name = new_linter.class.name.split('::').last
        next unless enabled_linter.include? name
        next if disabled_linter.include? name
        @linter.push new_linter
      end
    end

    def analyze(file)
      @files[file] = parse file
    end

    def parse(file)
      to_json File.read(file)
    end

    def report
      issues = @linter.map do |linter|
        linter.lint_files(@files, disable_tags)
        linter.issues
      end.flatten

      issues.each { |issue| puts issue.render }

      return 0 if issues.select { |issue| issue.class == Error }.empty?
      -1
    end

    def disable_tags
      LINTER.map { |lint| "disable#{lint.new.class.name.split('::').last}" }
    end

    def to_json(input)
      parser = Gherkin::Parser.new
      scanner = Gherkin::TokenScanner.new input

      parser.parse(scanner)
    end

    def print(issues)
      puts "There are #{issues.length} Issues" unless issues.empty?
      issues.each { |issue| puts issue }
    end
  end
end
