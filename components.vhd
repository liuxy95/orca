library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library work;

package components is

  component decode is
    generic(
      REGISTER_SIZE       : positive;
      REGISTER_NAME_SIZE  : positive;
      INSTRUCTION_SIZE    : positive;
      SIGN_EXTENSION_SIZE : positive);
    port(
      clk         : in std_logic;
      reset       : in std_logic;
      instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

      --writeback signals
      wb_sel    : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      wb_data   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
      wb_enable : in std_logic;

      --output signals
      rs1_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      rs2_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      sign_extension : out std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      --inputs just for carrying to next pipeline stage
      pc_next_in     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_curr_in     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_in       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      pc_next_out    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_curr_out    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_out      : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0));
  end component decode;

  component execute is
    generic(
      REGISTER_SIZE       : positive;
      REGISTER_NAME_SIZE  : positive;
      INSTRUCTION_SIZE    : positive;
      SIGN_EXTENSION_SIZE : positive);
    port(
      clk   : in std_logic;
      reset : in std_logic;

      pc_next     : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_current  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

      rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

      wb_sel  : inout std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_data : inout std_logic_vector(REGISTER_SIZE-1 downto 0);
      wb_en   : inout std_logic;

      predict_corr    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      predict_corr_en : out std_logic;

--memory-bus
      address    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      byte_en    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      write_en   : out std_logic;
      read_en    : out std_logic;
      write_data : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      read_data  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      busy       : in  std_logic);
  end component execute;

  component instruction_fetch is
    generic (
      REGISTER_SIZE    : positive;
      INSTRUCTION_SIZE : positive);
    port (
      clk        : in std_logic;
      reset      : in std_logic;
      pc_corr    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_corr_en : in std_logic;

      instr_out   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_out      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      next_pc_out : out std_logic_vector(REGISTER_SIZE-1 downto 0);

      instr_address : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_in      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_busy    : in  std_logic);
  end component instruction_fetch;

  component arithmetic_unit is
    generic (
      INSTRUCTION_SIZE    : integer;
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer);
    port (
      clk            : in  std_logic;
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable    : out std_logic);
  end component arithmetic_unit;

  component branch_unit is
    generic (
      REGISTER_SIZE       : integer;
      INSTRUCTION_SIZE    : integer;
      SIGN_EXTENSION_SIZE : integer);
    port (
      clk            : in  std_logic;
      reset          : in  std_logic;
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      current_pc     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      predicted_pc   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr          : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_out_en    : out std_logic;
      new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
      bad_predict    : out std_logic
      );
  end component branch_unit;

  component load_store_unit is
    generic (
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer;
      INSTRUCTION_SIZE    : integer);
    port (
      clk            : in  std_logic;
      valid          : in  std_logic;
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      stall          : out std_logic;
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable    : out std_logic;
--memory-bus
      address        : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      byte_en        : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      write_en       : out std_logic;
      read_en        : out std_logic;
      write_data     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      read_data      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      busy           : in  std_logic);
  end component load_store_unit;

  component true_dual_port_ram_single_clock is
    generic (
      DATA_WIDTH : natural := 8;
      ADDR_WIDTH : natural := 6
      );
    port (
      clk    : in  std_logic;
      addr_a : in  natural range 0 to 2**ADDR_WIDTH - 1;
      addr_b : in  natural range 0 to 2**ADDR_WIDTH - 1;
      data_a : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      data_b : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      we_a   : in  std_logic := '1';
      we_b   : in  std_logic := '1';
      q_a    : out std_logic_vector((DATA_WIDTH -1) downto 0);
      q_b    : out std_logic_vector((DATA_WIDTH -1) downto 0)
      );
  end component true_dual_port_ram_single_clock;


  component byte_enabled_true_dual_port_ram is
    generic (
      BYTES      : natural := 4;
      ADDR_WIDTH : natural);
    port (
      clk    : in  std_logic;
      addr1  : in  natural range 0 to 2**ADDR_WIDTH-1;
      addr2  : in  natural range 0 to 2**ADDR_WIDTH-1;
      wdata1 : in  std_logic_vector(BYTES*8-1 downto 0);
      wdata2 : in  std_logic_vector(BYTES*8-1 downto 0);
      we1    : in  std_logic;
      be1    : in  std_logic_vector(BYTES-1 downto 0);
      we2    : in  std_logic;
      be2    : in  std_logic_vector(BYTES-1 downto 0);
      rdata1 : out std_logic_vector(BYTES*8-1 downto 0);
      rdata2 : out std_logic_vector(BYTES*8-1 downto 0));
  end component byte_enabled_true_dual_port_ram;

  component memory_system is
    generic (
      REGISTER_SIZE : natural);
    port (
      clk        : in  std_logic;
      instr_addr : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_addr  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_we    : in  std_logic;
      data_be    : in  std_logic_vector(REGISTER_SIZE/8-1 downto 0);
      data_wdata : in  std_logic_vector(REGISTER_SIZE - 1 downto 0);
      data_rdata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_data : out std_logic_vector(REGISTER_SIZE-1 downto 0));
  end component memory_system;

  component register_file
    generic(
      REGISTER_SIZE      : positive;
      REGISTER_NAME_SIZE : positive);
    port(
      clk              : in std_logic;
      rs1_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      rs2_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      writeback_sel    : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      writeback_data   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
      writeback_enable : in std_logic;

      rs1_data : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      rs2_data : out std_logic_vector(REGISTER_SIZE -1 downto 0));
  end component register_file;

  component pc_incr is
    generic (
      REGISTER_SIZE    : positive;
      INSTRUCTION_SIZE : positive);
    port (
      pc      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr   : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      next_pc : out std_logic_vector(REGISTER_SIZE-1 downto 0));
  end component pc_incr;

end package components;