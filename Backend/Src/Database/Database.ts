import { createClient, PostgrestError } from "@supabase/supabase-js";

interface Database {
  public: {
    Tables: {
      Users: {
        id: number;
        created_at: Date;
        Name: string;
        email: string;
        password: string;
        role: string;
      };
    };
  };
}

const supabaseKey: string = process.env.SUPABASE_KEY as string,
  supabaseUrl: string = process.env.SUPABASE_URL as string,
  supabaseConnection = createClient<Database>(supabaseUrl, supabaseKey);

export const fetchUsers = async (): Promise<any[] | PostgrestError> => {
    try {
      const { data, error } = await supabaseConnection.from("Users").select();
      return error ? error : data;
    } catch (error) {
      throw error;
    }
  },
  fetchUser = async ({
    email,
  }: {
    email?: string;
  }): Promise<any[] | PostgrestError> => {
    try {
      const { data, error } = await supabaseConnection
        .from("Users")
        .select()
        .eq("Email", email);
      return data ? data : error;
    } catch (error) {
      throw error;
    }
  },
  insertUser = async ({
    name,
    email,
    password,
    role,
  }: {
    name: string;
    email: string;
    password: string;
    role: string;
  }): Promise<any[] | PostgrestError | string> => {
    try {
      const findUser = await fetchUser({ email: email });
      if (!(findUser instanceof PostgrestError)) {
        if (findUser.length > 0) {
          return "User already exists";
        } else {
          const { data, error } = await supabaseConnection
            .from("Users")
            .insert({
              created_at: new Date(),
              Name: name,
              Email: email,
              Password: password,
              Role: role,
            })
            .select();

          return error ? error : data != null ? data : [];
        }
      } else return findUser;
    } catch (error) {
      throw error;
    }
  },
  updateUser = async ({
    id,
    newId,
    name,
    email,
    password,
    role,
  }: {
    id: number;
    newId?: number;
    name?: string;
    email?: string;
    password?: string;
    role?: string;
  }): Promise<string | PostgrestError> => {
    try {
      const users = await fetchUsers();

      if (!(users instanceof PostgrestError)) {
        const user = users.find((user) => user.id == id);

        if (user) {
          const { error } = await supabaseConnection
            .from("Users")
            .update({
              id: newId ? newId : user.id,
              Name: name ? name : user.name,
              Email: email ? email : user.email,
              Password: password ? password : user.password,
              Role: role ? role : user.role,
            })
            .eq("id", id)
            .select("*");

          return error ? error : "Update successful";
        } else return "User doesn't exist";
      } else return "Error occurred, please try again";
    } catch (error) {
      throw error;
    }
  },
  deleteUser = async ({
    email,
  }: {
    email: string;
  }): Promise<string | PostgrestError> => {
    try {
      const user = await fetchUser({ email: email });
      let successUpdation: boolean = true;

      if (!(user instanceof PostgrestError)) {
        if (user.length > 0) {
          const { error } = await supabaseConnection
            .from("Users")
            .delete()
            .eq("Email", email);

          return error
            ? error
            : successUpdation
            ? "Success"
            : "Error occured in updating fields";
        } else return "User doesn't exist";
      } else {
        return "Error in fetching the database, please try again";
      }
    } catch (error) {
      throw error;
    }
  };
