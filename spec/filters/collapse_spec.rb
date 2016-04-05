# encoding: utf-8
require 'spec_helper'
require "logstash/filters/collapse"

describe LogStash::Filters::Collapse do

  describe "Test Map Fields" do
    let(:config) do <<-CONFIG
      filter {
        collapse {
          map_fields => { "[level_a][level_b][level_c]" => "level_field" "[level_a][level_d][level_e]" => "another_field"}
          multi_valued => false
        }
      }
    CONFIG
    end

    sample("level_a" => {"level_b" => {"level_c" => "valueA"},"level_d" => {"level_e" => "valueB"}}) do
      expect(subject).to include("level_field")
      expect(subject['level_field']).to eq(['valueA'])
      expect(subject).to include("another_field")
      expect(subject['another_field']).to eq(['valueB'])
    end
  end


  describe "Test List Fields" do
    let(:config) do <<-CONFIG
      filter {
        collapse {
          map_fields => { "[level_a][level_b][level_c]" => "level_field" "[level_a][level_d][level_e]" => "another_field"}
          multi_valued => false
        }
      }
    CONFIG
    end

    sample("level_a" => {"level_b" => [{"level_c" => "valueA"},{"level_c" => "valueB"}],"level_d" => [{"level_e" => "valueB"}]}) do
      expect(subject).to include("level_field")
      expect(subject['level_field']).to eq(['valueA','valueB'])
      expect(subject).to include("another_field")
      expect(subject['another_field']).to eq(['valueB'])
    end

    sample("level_a" => [{"level_b" => [{"level_c" => "valueA"},{"level_c" => "valueB"}],"level_d" => [{"level_e" => "valueB"}]},{"level_b" => [{"level_c" => "valueA"},{"level_c" => "valueB"}],"level_d" => [{"level_e" => "valueB"}]}]) do
      expect(subject).to include("level_field")
      expect(subject['level_field']).to eq(['valueA','valueB','valueA','valueB'])
      expect(subject).to include("another_field")
      expect(subject['another_field']).to eq(['valueB','valueB'])
    end
  end

  describe "Test Doesn't Exist" do
    let(:config) do <<-CONFIG
      filter {
        collapse {
          map_fields => { "[level_a][level_b]" => "level_field" "[level_a][level_d][level_e]" => "another_field"}
          multi_valued => false
        }
      }
    CONFIG
    end

    sample("level_a" => {"level_b" => [{"level_c" => "valueA"},{"level_c" => "valueB"}],"level_d" => [{"level_e" => "valueB"}]}) do
      expect(subject).not_to include("level_field")
      expect(subject).to include("another_field")
      expect(subject['another_field']).to eq(['valueB'])
    end

    sample("level_a" => {"level_b" => {"level_c" => "valueA"}}) do
      expect(subject).not_to include("level_field")
    end

  end

  describe "Test Array of values" do
    let(:config) do <<-CONFIG
      filter {
        collapse {
          map_fields => { "[level_a][level_b]" => "level_field"}
          multi_valued => false
        }
      }
    CONFIG
    end

    sample("level_a" => {"level_b" => ["valueA","valueB"]}) do
      expect(subject).to include("level_field")
      expect(subject['level_field']).to eq(['valueA','valueB'])
    end

  end


  describe "Test Same Fields" do
    let(:config) do <<-CONFIG
      filter {
        collapse {
          map_fields => { "[level_a][level_b][level_c]" => "level_field" "[level_a][level_d][level_e]" => "level_field"}
          multi_valued => false
        }
      }
    CONFIG
    end

    sample("level_a" => {"level_b" => [{"level_c" => "valueA"},{"level_c" => "valueB"}],"level_d" => [{"level_e" => "valueC"}]}) do
      expect(subject).to include("level_field")
      expect(subject['level_field']).to eq(['valueA','valueB',"valueC"])
    end

  end
end
